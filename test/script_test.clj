(ns script-test
  (:require [clojure.test :refer [deftest testing is use-fixtures]]
            [babashka.fs :as fs]
            [actions :as a]
            [cache :as c]
            [actions.script]))

(def ^:dynamic *tmp-file* nil)

(defn tmp-file-fixture [f]
  (let [tmp (str (fs/create-temp-file {:prefix "script-test-" :suffix ".txt"}))]
    (binding [*tmp-file* tmp]
      (try (f) (finally (fs/delete-if-exists tmp))))))

(use-fixtures :each tmp-file-fixture)

(deftest script-env-test
  (testing "script receives environment variables via :env"
    (a/install! :pkg/script {}
                {:test-script {:src (str "echo $SECRET > " *tmp-file*)
                               :env {:SECRET "injected"}}} {})
    (is (= "injected" (clojure.string/trim (slurp *tmp-file*)))))

  (testing "script without :env does not receive the var"
    (a/install! :pkg/script {}
                {:test-script {:src (str "echo \"${SECRET:-empty}\" > " *tmp-file*)}} {})
    (is (= "empty" (clojure.string/trim (slurp *tmp-file*))))))

(deftest script-install-cache-writeback-test
  (testing "successful script execution writes content hash to *cache*"
    (binding [a/*cache* (atom {})]
      (a/install! :pkg/script {}
                  {:my-script {:src "echo hello"}} {})
      (let [cached (c/get-script @a/*cache* "my-script")]
        (is (some? cached) "script should be in cache after execution")
        (is (= (c/content-hash "echo hello") (:content-hash cached))
            "cached hash should match script content"))))

  (testing "failed script execution does not write to cache"
    (binding [a/*cache* (atom {})]
      (a/install! :pkg/script {}
                  {:bad-script {:src "exit 1"}} {})
      (is (nil? (c/get-script @a/*cache* "bad-script"))
          "failed script should not be cached"))))

(defn- run [cache script]
  (binding [a/*cache* (atom cache)]
    (with-out-str (doall (a/install! :pkg/script {} {:s script} {})))
    @a/*cache*))

(deftest script-state-test
  (testing "what a run writes to its state file is stored as the script's state"
    (let [cache (run {} {:src "printf 'a\\nb\\n' > \"$DOTFILES_SCRIPT_STATE\""})]
      (is (= ["a" "b"] (:state (c/get-script cache "s"))))))

  (testing "a run starts from the state the last successful run stored"
    (let [cache (run {:scripts {"s" {:state ["a" "b"]}}}
                     {:src (str "cp \"$DOTFILES_SCRIPT_STATE\" " *tmp-file*)})]
      (is (= "a\nb\n" (slurp *tmp-file*)))
      (is (= ["a" "b"] (:state (c/get-script cache "s"))) "state the run leaves alone is kept")))

  (testing "a script that never touches its state file stores none"
    (is (= [] (:state (c/get-script (run {} {:src "true"}) "s")))))

  (testing "a failed run keeps the previous state"
    (let [cache (run {:scripts {"s" {:state ["a"]}}}
                     {:src "echo b > \"$DOTFILES_SCRIPT_STATE\"; exit 1"})]
      (is (= ["a"] (:state (c/get-script cache "s")))))))

(deftest script-check-state-test
  (testing "a check reads the state the last successful run stored"
    (binding [a/*cache* (atom {:scripts {"s" {:state ["owned"]}}})]
      (is (true? (a/run-query [:script "s" {:src "true" :check "grep -qx owned \"$DOTFILES_SCRIPT_STATE\""}])))))

  (testing "what a check writes to its state file is not stored"
    (binding [a/*cache* (atom {:scripts {"s" {:state ["owned"]}}})]
      (a/run-query [:script "s" {:src "true" :check "echo other > \"$DOTFILES_SCRIPT_STATE\""}])
      (is (= ["owned"] (:state (c/get-script @a/*cache* "s")))))))
