(ns script-test
  (:require [clojure.test :refer [deftest testing is use-fixtures]]
            [babashka.fs :as fs]
            [actions :as a]
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
                               :env {:SECRET "injected"}}})
    (is (= "injected" (clojure.string/trim (slurp *tmp-file*)))))

  (testing "script without :env does not receive the var"
    (a/install! :pkg/script {}
                {:test-script {:src (str "echo \"${SECRET:-empty}\" > " *tmp-file*)}})
    (is (= "empty" (clojure.string/trim (slurp *tmp-file*))))))
