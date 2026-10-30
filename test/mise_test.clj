(ns mise-test
  (:require [clojure.test :refer [deftest testing is]]
            [actions :as a]
            [outcome :as o]
            [registry]
            [support]))

(defn- install-calls
  [items]
  (let [calls (atom [])]
    (with-redefs [a/exec! (fn [_ cmd] (swap! calls conj cmd) {:exit 0})]
      (with-out-str (doall (a/install! :pkg/mise {} items {}))))
    @calls))

(deftest mise-install-commands-test
  (testing "a global version is selected with mise use --global"
    (is (= [["mise" "use" "--global" "node@20"]]
           (install-calls {:node {:global "20"}}))))

  (testing "an :install version is installed without being selected"
    (is (= [["mise" "install" "node@20"]]
           (install-calls {:node {:install #{"20"}}}))))

  (testing "a global and :install versions run both, global first"
    (is (= [["mise" "use" "--global" "java@25"]
            ["mise" "install" "java@17" "java@21"]]
           (install-calls {:java {:global "25" :install #{"21" "17"}}}))))

  (testing "the global version listed in :install too is only selected"
    (is (= [["mise" "use" "--global" "java@25"]
            ["mise" "install" "java@21"]]
           (install-calls {:java {:global "25" :install #{"25" "21"}}}))))

  (testing "the global version as the only :install version installs nothing else"
    (is (= [["mise" "use" "--global" "java@25"]]
           (install-calls {:java {:global "25" :install #{"25"}}})))))

(deftest mise-install-stops-at-first-failure-test
  (let [calls (atom [])
        results (with-redefs [a/exec! (fn [_ cmd] (swap! calls conj cmd) {:exit 1 :err "boom"})]
                  (with-out-str (doall (a/install! :pkg/mise {} {:java {:global "25" :install #{"21"}}} {})))
                  @calls)]
    (is (= [["mise" "use" "--global" "java@25"]] results))))

(deftest mise-queries-test
  (testing "a latest global also asks what is outdated"
    (is (= #{[:mise :installed] [:mise :outdated] [:mise :global "bun"]}
           (a/queries :pkg/mise {:bun {:global "latest"}}))))

  (testing "a latest :install version also asks what is outdated"
    (is (= #{[:mise :installed] [:mise :outdated]}
           (a/queries :pkg/mise {:bun {:install #{"latest"}}}))))

  (testing "a :global entry also asks what the global config requests for its tool"
    (is (= #{[:mise :installed] [:mise :global "node"]}
           (a/queries :pkg/mise {:node {:global "20" :install #{"18"}}})))))

(defn- check
  ([opts installed] (check opts installed (:global opts)))
  ([opts installed global-request]
   (a/check :pkg/mise :java opts (support/facts-of {[:mise :installed] installed
                                                    [:mise :global "java"] global-request}))))

(deftest mise-check-global-request-test
  (testing "the global config requesting the :global version → satisfied"
    (is (o/satisfied? (check {:global "25"} {"java" #{"25"}} "25"))))

  (testing "the global config requesting something else → drift from it to :global"
    (let [result (check {:global "24.14.0"} {"java" #{"24.14.0"}} "lts")]
      (is (o/drift? result))
      (is (= "lts → 24.14.0" (:message result)))))

  (testing "no global request for a :global tool → drift"
    (let [result (check {:global "25"} {"java" #{"25"}} nil)]
      (is (o/drift? result))
      (is (= "unset → 25" (:message result)))))

  (testing "a request that isn't one version string → drift"
    (is (o/drift? (check {:global "24"} {"java" #{"24"}} "[\"24\", \"22\"]")))))

(deftest mise-check-multi-version-test
  (testing "every declared version installed → satisfied"
    (is (o/satisfied? (check {:global "25" :install #{"21"}} {"java" #{"21" "25"}}))))

  (testing "an :install version missing → drift to it"
    (let [result (check {:global "25" :install #{"21"}} {"java" #{"25"}})]
      (is (o/drift? result))
      (is (= "25 → 21" (:message result)))))

  (testing "the global missing → drift to it"
    (let [result (check {:global "25" :install #{"21"}} {"java" #{"21"}})]
      (is (= "21 → 25" (:message result)))))

  (testing "the global listed in :install too needs no second install"
    (is (o/satisfied? (check {:global "25" :install #{"25"}} {"java" #{"25"}})))))

(deftest mise-check-shape-test
  (testing "neither :global nor :install → error"
    (is (o/error? (check {} {"java" #{"25"}}))))

  (testing "an empty :install and no :global → error"
    (is (o/error? (check {:install #{}} {"java" #{"25"}}))))

  (testing "the old :version shape → error rather than silently ignored"
    (is (o/error? (check {:version "25" :global true} {"java" #{"25"}}))))

  (testing ":install as a bare string → error"
    (is (o/error? (check {:install "21"} {"java" #{"21"}}))))

  (testing ":global as anything but a version string → error"
    (is (o/error? (check {:global true} {"java" #{"25"}})))))
