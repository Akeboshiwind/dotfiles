(ns trust-test
  "Propagated from syn.allium — package-source trust.

   Spec constructs covered:
   - CheckPackages trust branches (PackageAction.trusted / trust_declared)
   - AppliedTrustMatchesDeclaration invariant, as apply-side command
     reconciliation: the commands issued converge the live grant on the
     declaration
   - ScheduleOrphanSourceRemovals / SourceRemovalAction (:brew/untap)
   - ExecuteActions trust guidance: grant before install, per-formula
     grants, uninstall revokes"
  (:require [clojure.test :refer [deftest testing is]]
            [clojure.string :as str]
            [actions :as a]
            [actions.brew :as brew]
            [outcome :as o]
            [utils :as u]
            [registry]
            [support]))

(def no-trust (delay {:formulae #{} :taps #{}}))

;; =============================================================================
;; tap-of
;; =============================================================================

(deftest tap-of-test
  (testing "tap-qualified names yield their tap"
    (is (= "babashka/brew" (brew/tap-of "babashka/brew/bbin")))
    (is (= "borkdude/brew" (brew/tap-of "borkdude/brew/babashka"))))

  (testing "official names yield nil — trust does not apply"
    (is (nil? (brew/tap-of "neovim")))
    (is (nil? (brew/tap-of "postgresql@18")))))

;; =============================================================================
;; CheckPackages trust branches
;; =============================================================================

(deftest brew-check-declared-ungranted-test
  (testing "declared :trust, not yet trusted → drift(:wrong), granted on apply"
    (let [facts (support/facts-of {[:brew :formulae] #{"babashka"} [:brew :casks] #{} [:brew :outdated] {} [:brew :trusted] @no-trust})]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {:trust true} facts)]
        (is (o/drift? result))
        (is (= :wrong (:kind result))))))

  (testing "declared :trust, untrusted and missing → still trust drift(:wrong)"
    (let [facts (support/facts-of {[:brew :formulae] #{} [:brew :casks] #{} [:brew :outdated] {} [:brew :trusted] @no-trust})]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {:trust true} facts)]
        (is (o/drift? result))
        (is (= :wrong (:kind result)))))))

(deftest brew-check-undeclared-granted-test
  (testing "trusted but :trust not declared → drift(:wrong), revoked on apply"
    (let [facts (support/facts-of {[:brew :formulae] #{"babashka"} [:brew :casks] #{} [:brew :outdated] {} [:brew :trusted] {:formulae #{"borkdude/brew/babashka"} :taps #{}}})]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {} facts)]
        (is (o/drift? result))
        (is (= :wrong (:kind result)))))))

(deftest brew-check-unconsented-installed-test
  (testing "untrusted, no :trust, installed → satisfied but warned to declare :trust"
    (let [facts (support/facts-of {[:brew :formulae] #{"babashka"} [:brew :casks] #{} [:brew :outdated] {} [:brew :trusted] @no-trust})]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {} facts)]
        (is (o/satisfied? result))
        (is (string? (:message result)))
        (is (str/includes? (:message result) ":trust"))))))

(deftest brew-check-unconsented-missing-test
  (testing "untrusted, no :trust, not installed → conflict (install is known to fail)"
    (let [facts (support/facts-of {[:brew :formulae] #{} [:brew :casks] #{} [:brew :outdated] {} [:brew :trusted] @no-trust})]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {} facts)]
        (is (o/conflict? result))
        (is (str/includes? (str (:message result)) ":trust"))))))

(deftest brew-check-trusted-declared-test
  (testing "declared :trust and trusted, installed → satisfied, no warning"
    (let [facts (support/facts-of {[:brew :formulae] #{"babashka"} [:brew :casks] #{} [:brew :outdated] {} [:brew :trusted] {:formulae #{"borkdude/brew/babashka"} :taps #{}}})]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {:trust true} facts)]
        (is (o/satisfied? result))
        (is (nil? (:message result)))))))

(deftest brew-check-whole-tap-trust-test
  (testing "a grant for the whole tap counts as trusted (e.g. granted by hand)"
    (let [facts (support/facts-of {[:brew :formulae] #{"babashka"} [:brew :casks] #{} [:brew :outdated] {} [:brew :trusted] {:formulae #{} :taps #{"borkdude/brew"}}})]
      (is (o/satisfied? (a/check :pkg/brew "borkdude/brew/babashka" {:trust true} facts))))))

(deftest brew-check-official-inert-test
  (testing "official formulae never enter trust branches"
    (let [facts (support/facts-of {[:brew :formulae] #{"neovim"} [:brew :casks] #{} [:brew :outdated] {} [:brew :trusted] @no-trust})]
      (let [result (a/check :pkg/brew :neovim {} facts)]
        (is (o/satisfied? result))
        (is (nil? (:message result))))
      ;; :trust on an official package is meaningless and inert
      (is (o/satisfied? (a/check :pkg/brew :neovim {:trust true} facts)))))

  (testing "missing official formula is plain drift(:missing), unchanged"
    (let [facts (support/facts-of {[:brew :formulae] #{} [:brew :casks] #{} [:brew :outdated] {} [:brew :trusted] @no-trust})]
      (let [result (a/check :pkg/brew :neovim {} facts)]
        (is (o/drift? result))
        (is (= :missing (:kind result)))))))

(deftest brew-check-trust-precedes-outdated-test
  (testing "trust drift wins over outdated — brew's answers are unreliable for ignored taps"
    (let [facts (support/facts-of {[:brew :formulae] #{"babashka"} [:brew :casks] #{} [:brew :outdated] {"babashka" {:installed "1.0" :current "1.1"}} [:brew :trusted] @no-trust})]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {:trust true} facts)]
        (is (o/drift? result))
        (is (= :wrong (:kind result))))))

  (testing "trusted and declared, outdated → normal drift(:outdated)"
    (let [facts (support/facts-of {[:brew :formulae] #{"babashka"} [:brew :casks] #{} [:brew :outdated] {"babashka" {:installed "1.0" :current "1.1"}} [:brew :trusted] {:formulae #{"borkdude/brew/babashka"} :taps #{}}})]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {:trust true} facts)]
        (is (o/drift? result))
        (is (= :outdated (:kind result)))))))

;; =============================================================================
;; Apply reconciles trust with the declaration
;; (AppliedTrustMatchesDeclaration, observed through the issued commands)
;; =============================================================================

(defn- mock-exec!
  "Returns a mock exec! fn that tracks calls in `calls` atom."
  [calls]
  (fn [_opts args]
    (swap! calls conj args)
    {:exit 0 :err nil}))

(deftest brew-install-grants-declared-trust-test
  (testing "declared :trust on an untrusted missing item → per-formula grant, then install"
    (let [calls (atom [])]
      (let [facts (support/facts-of {[:brew :formulae] #{} [:brew :casks] #{} [:brew :trusted] @no-trust})]
        (with-redefs [a/exec! (mock-exec! calls)]
          (a/install! :pkg/brew {} {"borkdude/brew/babashka" {:trust true}} facts)))
      (let [trust-idx (.indexOf @calls ["brew" "trust" "--formula" "borkdude/brew/babashka"])
            install-idx (.indexOf @calls ["brew" "install" "borkdude/brew/babashka"])]
        (is (nat-int? trust-idx) "grants trust per formula, never the whole tap")
        (is (nat-int? install-idx) "installs the package")
        (is (< trust-idx install-idx) "grant precedes install so brew will load the formula")))))

(deftest brew-install-grant-only-test
  (testing "declared :trust on an untrusted but installed item → grant only, no reinstall"
    (let [calls (atom [])]
      (let [facts (support/facts-of {[:brew :formulae] #{"babashka"} [:brew :casks] #{} [:brew :trusted] @no-trust})]
        (with-redefs [a/exec! (mock-exec! calls)]
          (a/install! :pkg/brew {} {"borkdude/brew/babashka" {:trust true}} facts)))
      (is (nat-int? (.indexOf @calls ["brew" "trust" "--formula" "borkdude/brew/babashka"])))
      (is (neg? (.indexOf @calls ["brew" "install" "borkdude/brew/babashka"]))))))

(deftest brew-install-revokes-undeclared-trust-test
  (testing "trusted but :trust not declared → revoke, nothing installed"
    (let [calls (atom [])]
      (let [facts (support/facts-of {[:brew :formulae] #{"babashka"} [:brew :casks] #{} [:brew :trusted] {:formulae #{"borkdude/brew/babashka"} :taps #{}}})]
        (with-redefs [a/exec! (mock-exec! calls)]
          (a/install! :pkg/brew {} {"borkdude/brew/babashka" {}} facts)))
      (is (nat-int? (.indexOf @calls ["brew" "untrust" "--formula" "borkdude/brew/babashka"])))
      (is (neg? (.indexOf @calls ["brew" "install" "borkdude/brew/babashka"]))))))

(deftest brew-install-reconciled-needs-no-trust-commands-test
  (testing "trusted and declared → plain install, no trust commands"
    (let [calls (atom [])]
      (let [facts (support/facts-of {[:brew :formulae] #{} [:brew :casks] #{} [:brew :trusted] {:formulae #{"borkdude/brew/babashka"} :taps #{}}})]
        (with-redefs [a/exec! (mock-exec! calls)]
          (a/install! :pkg/brew {} {"borkdude/brew/babashka" {:trust true}} facts)))
      (is (= [["brew" "install" "borkdude/brew/babashka"]] @calls))))

  (testing "official item never gets trust commands, even with a stray :trust"
    (let [calls (atom [])]
      (let [facts (support/facts-of {[:brew :formulae] #{} [:brew :casks] #{} [:brew :trusted] @no-trust})]
        (with-redefs [a/exec! (mock-exec! calls)]
          (a/install! :pkg/brew {} {:neovim {:trust true}} facts)))
      (is (= [["brew" "install" "neovim"]] @calls)))))

(deftest brew-remove-extras-revokes-trust-test
  (testing "removing a trusted tap-qualified extra also untrusts it"
    (let [calls (atom [])
          facts (support/facts-of {[:brew :trusted] {:formulae #{"babashka/brew/bbin"} :taps #{}}})]
      (with-redefs [a/exec! (mock-exec! calls)]
        (with-out-str (a/remove-extras! :pkg/brew {} [{:name "babashka/brew/bbin"}] facts)))
      (is (= [["brew" "untrust" "--formula" "babashka/brew/bbin"]
              ["brew" "uninstall" "babashka/brew/bbin"]
              ["brew" "autoremove"]]
             @calls))))

  (testing "untrusted extras uninstall without trust commands"
    (let [calls (atom [])]
      (with-redefs [a/exec! (mock-exec! calls)]
        (with-out-str (a/remove-extras! :pkg/brew {} [{:name "wget"}]
                                        (support/facts-of {[:brew :trusted] @no-trust}))))
      (is (not-any? #(= "untrust" (second %)) @calls)))))

(deftest extra-taps-test
  (testing "an installed tap no declared package comes from is extra"
    (is (= #{"oven-sh/bun"}
           (brew/extra-taps #{"babashka/brew" "oven-sh/bun"} #{"babashka/brew/bbin" "neovim"}))))

  (testing "taps declared packages come from are kept"
    (is (empty? (brew/extra-taps #{"borkdude/brew"} #{"borkdude/brew/babashka" "borkdude/brew/clj-kondo"}))))

  (testing "no installed taps, no extras"
    (is (empty? (brew/extra-taps #{} #{"babashka/brew/bbin"})))))

(deftest brew-extras-include-taps-test
  (testing "extra taps are listed after extra packages, marked as taps"
    (is (= [{:name "wget"} {:name "oven-sh/bun" :tap true}]
           (a/extras :pkg/brew #{"neovim"}
                     (support/facts-of {[:command "brew"] true
                                        [:brew :leaves] #{"neovim" "wget"}
                                        [:brew :casks-full] #{}
                                        [:brew :taps] #{"oven-sh/bun"}})))))

  (testing "an extra cask is marked as one, packages still in name order"
    (is (= [{:name "slack" :cask true} {:name "wget"}]
           (a/extras :pkg/brew #{"neovim"}
                     (support/facts-of {[:command "brew"] true
                                        [:brew :leaves] #{"neovim" "wget"}
                                        [:brew :casks-full] #{"slack"}
                                        [:brew :taps] #{}}))))))

(deftest brew-remove-extras-untaps-after-uninstalls-test
  (testing "packages are uninstalled before their taps are removed"
    (let [calls (atom [])]
      (with-redefs [a/exec! (mock-exec! calls)]
        (with-out-str (a/remove-extras! :pkg/brew {} [{:name "wget"} {:name "oven-sh/bun" :tap true}]
                                        (support/facts-of {[:brew :trusted] @no-trust}))))
      (is (= [["brew" "uninstall" "wget"] ["brew" "autoremove"] ["brew" "untap" "oven-sh/bun"]]
             @calls)))))
