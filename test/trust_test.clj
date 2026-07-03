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
            [plan :as p]
            [utils :as u]
            [registry]))

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
    (binding [brew/*formulae-cache* (delay #{"babashka"})
              brew/*casks-cache* (delay #{})
              brew/*outdated-cache* (delay {})
              brew/*trusted-cache* no-trust]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {:trust true})]
        (is (o/drift? result))
        (is (= :wrong (:kind result))))))

  (testing "declared :trust, untrusted and missing → still trust drift(:wrong)"
    (binding [brew/*formulae-cache* (delay #{})
              brew/*casks-cache* (delay #{})
              brew/*outdated-cache* (delay {})
              brew/*trusted-cache* no-trust]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {:trust true})]
        (is (o/drift? result))
        (is (= :wrong (:kind result)))))))

(deftest brew-check-undeclared-granted-test
  (testing "trusted but :trust not declared → drift(:wrong), revoked on apply"
    (binding [brew/*formulae-cache* (delay #{"babashka"})
              brew/*casks-cache* (delay #{})
              brew/*outdated-cache* (delay {})
              brew/*trusted-cache* (delay {:formulae #{"borkdude/brew/babashka"} :taps #{}})]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {})]
        (is (o/drift? result))
        (is (= :wrong (:kind result)))))))

(deftest brew-check-unconsented-installed-test
  (testing "untrusted, no :trust, installed → satisfied but warned to declare :trust"
    (binding [brew/*formulae-cache* (delay #{"babashka"})
              brew/*casks-cache* (delay #{})
              brew/*outdated-cache* (delay {})
              brew/*trusted-cache* no-trust]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {})]
        (is (o/satisfied? result))
        (is (string? (:message result)))
        (is (str/includes? (:message result) ":trust"))))))

(deftest brew-check-unconsented-missing-test
  (testing "untrusted, no :trust, not installed → conflict (install is known to fail)"
    (binding [brew/*formulae-cache* (delay #{})
              brew/*casks-cache* (delay #{})
              brew/*outdated-cache* (delay {})
              brew/*trusted-cache* no-trust]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {})]
        (is (o/conflict? result))
        (is (str/includes? (str (:message result)) ":trust"))))))

(deftest brew-check-trusted-declared-test
  (testing "declared :trust and trusted, installed → satisfied, no warning"
    (binding [brew/*formulae-cache* (delay #{"babashka"})
              brew/*casks-cache* (delay #{})
              brew/*outdated-cache* (delay {})
              brew/*trusted-cache* (delay {:formulae #{"borkdude/brew/babashka"} :taps #{}})]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {:trust true})]
        (is (o/satisfied? result))
        (is (nil? (:message result)))))))

(deftest brew-check-whole-tap-trust-test
  (testing "a grant for the whole tap counts as trusted (e.g. granted by hand)"
    (binding [brew/*formulae-cache* (delay #{"babashka"})
              brew/*casks-cache* (delay #{})
              brew/*outdated-cache* (delay {})
              brew/*trusted-cache* (delay {:formulae #{} :taps #{"borkdude/brew"}})]
      (is (o/satisfied? (a/check :pkg/brew "borkdude/brew/babashka" {:trust true}))))))

(deftest brew-check-official-inert-test
  (testing "official formulae never enter trust branches"
    (binding [brew/*formulae-cache* (delay #{"neovim"})
              brew/*casks-cache* (delay #{})
              brew/*outdated-cache* (delay {})
              brew/*trusted-cache* no-trust]
      (let [result (a/check :pkg/brew :neovim {})]
        (is (o/satisfied? result))
        (is (nil? (:message result))))
      ;; :trust on an official package is meaningless and inert
      (is (o/satisfied? (a/check :pkg/brew :neovim {:trust true})))))

  (testing "missing official formula is plain drift(:missing), unchanged"
    (binding [brew/*formulae-cache* (delay #{})
              brew/*casks-cache* (delay #{})
              brew/*outdated-cache* (delay {})
              brew/*trusted-cache* no-trust]
      (let [result (a/check :pkg/brew :neovim {})]
        (is (o/drift? result))
        (is (= :missing (:kind result)))))))

(deftest brew-check-trust-precedes-outdated-test
  (testing "trust drift wins over outdated — brew's answers are unreliable for ignored taps"
    (binding [brew/*formulae-cache* (delay #{"babashka"})
              brew/*casks-cache* (delay #{})
              brew/*outdated-cache* (delay {"babashka" {:installed "1.0" :current "1.1"}})
              brew/*trusted-cache* no-trust]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {:trust true})]
        (is (o/drift? result))
        (is (= :wrong (:kind result))))))

  (testing "trusted and declared, outdated → normal drift(:outdated)"
    (binding [brew/*formulae-cache* (delay #{"babashka"})
              brew/*casks-cache* (delay #{})
              brew/*outdated-cache* (delay {"babashka" {:installed "1.0" :current "1.1"}})
              brew/*trusted-cache* (delay {:formulae #{"borkdude/brew/babashka"} :taps #{}})]
      (let [result (a/check :pkg/brew "borkdude/brew/babashka" {:trust true})]
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
      (binding [brew/*formulae-cache* (delay #{})
                brew/*casks-cache* (delay #{})
                brew/*trusted-cache* no-trust]
        (with-redefs [a/exec! (mock-exec! calls)]
          (a/install! :pkg/brew {} {"borkdude/brew/babashka" {:trust true}})))
      (let [trust-idx (.indexOf @calls ["brew" "trust" "--formula" "borkdude/brew/babashka"])
            install-idx (.indexOf @calls ["brew" "install" "borkdude/brew/babashka"])]
        (is (nat-int? trust-idx) "grants trust per formula, never the whole tap")
        (is (nat-int? install-idx) "installs the package")
        (is (< trust-idx install-idx) "grant precedes install so brew will load the formula")))))

(deftest brew-install-grant-only-test
  (testing "declared :trust on an untrusted but installed item → grant only, no reinstall"
    (let [calls (atom [])]
      (binding [brew/*formulae-cache* (delay #{"babashka"})
                brew/*casks-cache* (delay #{})
                brew/*trusted-cache* no-trust]
        (with-redefs [a/exec! (mock-exec! calls)]
          (a/install! :pkg/brew {} {"borkdude/brew/babashka" {:trust true}})))
      (is (nat-int? (.indexOf @calls ["brew" "trust" "--formula" "borkdude/brew/babashka"])))
      (is (neg? (.indexOf @calls ["brew" "install" "borkdude/brew/babashka"]))))))

(deftest brew-install-revokes-undeclared-trust-test
  (testing "trusted but :trust not declared → revoke, nothing installed"
    (let [calls (atom [])]
      (binding [brew/*formulae-cache* (delay #{"babashka"})
                brew/*casks-cache* (delay #{})
                brew/*trusted-cache* (delay {:formulae #{"borkdude/brew/babashka"} :taps #{}})]
        (with-redefs [a/exec! (mock-exec! calls)]
          (a/install! :pkg/brew {} {"borkdude/brew/babashka" {}})))
      (is (nat-int? (.indexOf @calls ["brew" "untrust" "--formula" "borkdude/brew/babashka"])))
      (is (neg? (.indexOf @calls ["brew" "install" "borkdude/brew/babashka"]))))))

(deftest brew-install-reconciled-needs-no-trust-commands-test
  (testing "trusted and declared → plain install, no trust commands"
    (let [calls (atom [])]
      (binding [brew/*formulae-cache* (delay #{})
                brew/*casks-cache* (delay #{})
                brew/*trusted-cache* (delay {:formulae #{"borkdude/brew/babashka"} :taps #{}})]
        (with-redefs [a/exec! (mock-exec! calls)]
          (a/install! :pkg/brew {} {"borkdude/brew/babashka" {:trust true}})))
      (is (= [["brew" "install" "borkdude/brew/babashka"]] @calls))))

  (testing "official item never gets trust commands, even with a stray :trust"
    (let [calls (atom [])]
      (binding [brew/*formulae-cache* (delay #{})
                brew/*casks-cache* (delay #{})
                brew/*trusted-cache* no-trust]
        (with-redefs [a/exec! (mock-exec! calls)]
          (a/install! :pkg/brew {} {:neovim {:trust true}})))
      (is (= [["brew" "install" "neovim"]] @calls)))))

;; =============================================================================
;; Uninstall revokes the orphan's grant
;; =============================================================================

(deftest brew-uninstall-revokes-trust-test
  (testing "uninstalling a trusted tap-qualified orphan also untrusts it"
    (let [calls (atom [])]
      (binding [brew/*trusted-cache* (delay {:formulae #{"babashka/brew/bbin"} :taps #{}})]
        (with-redefs [a/exec! (mock-exec! calls)]
          (a/install! :pkg/brew-uninstall {} {"babashka/brew/bbin" {}})))
      (is (nat-int? (.indexOf @calls ["brew" "untrust" "--formula" "babashka/brew/bbin"])))
      (is (nat-int? (.indexOf @calls ["brew" "uninstall" "babashka/brew/bbin"])))))

  (testing "untrusted orphans uninstall without trust commands"
    (let [calls (atom [])]
      (binding [brew/*trusted-cache* no-trust]
        (with-redefs [a/exec! (mock-exec! calls)]
          (a/install! :pkg/brew-uninstall {} {"wget" {}})))
      (is (not-any? #(= "untrust" (second %)) @calls)))))

;; =============================================================================
;; ScheduleOrphanSourceRemovals / SourceRemovalAction (:brew/untap)
;; =============================================================================

(deftest orphan-taps-test
  (testing "installed tap not implied by any declared package is orphaned"
    (is (= {"oven-sh/bun" {}}
           (brew/orphan-taps #{"babashka/brew" "oven-sh/bun"}
                             {"babashka/brew/bbin" {} :neovim {}}))))

  (testing "taps implied by declared packages are kept"
    (is (empty? (brew/orphan-taps #{"borkdude/brew"}
                                  {"borkdude/brew/babashka" {} "borkdude/brew/clj-kondo" {}}))))

  (testing "no installed taps, no orphans"
    (is (empty? (brew/orphan-taps #{} {"babashka/brew/bbin" {}})))))

(deftest brew-untap-check-test
  (testing "orphaned tap → drift(:orphan)"
    (let [result (a/check :brew/untap "oven-sh/bun" {})]
      (is (o/drift? result))
      (is (= :orphan (:kind result))))))

(deftest brew-untap-action-test
  (testing ":brew/untap removes the tap"
    (let [calls (atom [])]
      (with-redefs [a/exec! (mock-exec! calls)]
        (a/install! :brew/untap {} {"oven-sh/bun" {}}))
      (is (some #(= ["brew" "untap" "oven-sh/bun"] %) @calls))))

  (testing ":brew/untap orders within the brew family"
    (is (= [:complete :pkg/brew] (a/requires :brew/untap)))))

(deftest brew-orphans-includes-untap-test
  (testing "a/orphans :pkg/brew reports orphan taps alongside package orphans"
    (with-redefs [u/command-exists? (fn [cmd] (= cmd "brew"))
                  brew/leaves-set (fn [] #{"wget"})
                  brew/installed-set-full (fn [_] #{})
                  brew/installed-taps (fn [] #{"oven-sh/bun"})]
      (let [result (a/orphans :pkg/brew {:neovim {}})]
        (is (= {"wget" {}} (:pkg/brew-uninstall result)))
        (is (= {"oven-sh/bun" {}} (:brew/untap result)))))))

(deftest calculate-orphans-preserves-untap-test
  (testing "untap orphans survive plan merging (base-type injection must not clobber them)"
    (with-redefs [u/command-exists? (fn [cmd] (= cmd "brew"))
                  brew/leaves-set (fn [] #{})
                  brew/installed-set-full (fn [_] #{})
                  brew/installed-taps (fn [] #{"oven-sh/bun"})]
      (let [result (p/calculate-orphans {:pkg/brew {:neovim {}}})]
        (is (= {"oven-sh/bun" {}} (:brew/untap result))))))

  (testing "orphans for types absent from the plan still get their graph dependency injected"
    (with-redefs [u/command-exists? (fn [cmd] (= cmd "brew"))
                  brew/leaves-set (fn [] #{"wget"})
                  brew/installed-set-full (fn [_] #{})
                  brew/installed-taps (fn [] #{"oven-sh/bun"})]
      (let [result (p/calculate-orphans {})]
        (is (= {"wget" {}} (:pkg/brew-uninstall result)))
        (is (= {"oven-sh/bun" {}} (:brew/untap result)))
        (is (= {} (:pkg/brew result)) ":pkg/brew injected so [:complete :pkg/brew] resolves")))))
