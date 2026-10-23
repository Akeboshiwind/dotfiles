(ns mise-test
  (:require [clojure.test :refer [deftest testing is]]
            [actions :as a]
            [registry]))

(defn- install-calls
  [items]
  (let [calls (atom [])]
    (with-redefs [a/exec! (fn [_ cmd] (swap! calls conj cmd) {:exit 0})]
      (with-out-str (doall (a/install! :pkg/mise {} items {}))))
    @calls))

(deftest mise-install-commands-test
  (testing "a global version is selected with mise use --global"
    (is (= [["mise" "use" "--global" "node@20"]]
           (install-calls {:node {:version "20" :global true}}))))

  (testing "a non-global version is installed without being selected"
    (is (= [["mise" "install" "node@20"]]
           (install-calls {:node {:version "20"}})))))

(deftest mise-queries-test
  (testing "a latest version also asks what is outdated"
    (is (= #{[:mise :installed] [:mise :outdated]}
           (a/queries :pkg/mise {:bun {:version "latest" :global true}}))))

  (testing "pinned versions only ask what is installed"
    (is (= #{[:mise :installed]}
           (a/queries :pkg/mise {:node {:version "20" :global true}})))))
