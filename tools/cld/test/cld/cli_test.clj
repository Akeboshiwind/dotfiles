(ns cld.cli-test
  (:require [clojure.test :refer [deftest testing is]]
            [cld.cli :as cli]))

(deftest parse-args-test
  (testing "empty args -> start in cwd"
    (is (= {:command :start :project nil :opts {}}
           (cli/parse-args []))))

  (testing "single positional -> project name"
    (is (= {:command :start :project "myapp" :opts {}}
           (cli/parse-args ["myapp"]))))

  (testing "-n flag -> session name"
    (is (= {:command :start :project "myapp" :opts {:session-name "testing"}}
           (cli/parse-args ["myapp" "-n" "testing"]))))

  (testing "-n flag before project"
    (is (= {:command :start :project "myapp" :opts {:session-name "testing"}}
           (cli/parse-args ["-n" "testing" "myapp"]))))

  (testing "-w flag -> windows count"
    (is (= {:command :start :project "myapp" :opts {:windows 3}}
           (cli/parse-args ["myapp" "-w" "3"]))))

  (testing "combined flags"
    (is (= {:command :start :project "myapp" :opts {:session-name "test" :windows 2}}
           (cli/parse-args ["myapp" "-n" "test" "-w" "2"]))))

  (testing "-l -> list"
    (is (= {:command :list :filter nil}
           (cli/parse-args ["-l"]))))

  (testing "-l with filter"
    (is (= {:command :list :filter "api"}
           (cli/parse-args ["-l" "api"]))))

  (testing "ls alias"
    (is (= {:command :list :filter nil}
           (cli/parse-args ["ls"]))))

  (testing "-k -> kill"
    (is (= {:command :kill :target "myapp"}
           (cli/parse-args ["-k" "myapp"]))))

  (testing "-k without target -> error"
    (is (= :error (:command (cli/parse-args ["-k"])))))

  (testing "-r -> rename"
    (is (= {:command :rename :old "old-name" :new "new-name"}
           (cli/parse-args ["-r" "old-name" "new-name"]))))

  (testing "-r without args -> error"
    (is (= :error (:command (cli/parse-args ["-r"])))))

  (testing "-r with only one arg -> error"
    (is (= :error (:command (cli/parse-args ["-r" "old"])))))

  (testing "-s -> select"
    (is (= {:command :select}
           (cli/parse-args ["-s"]))))

  (testing "-h -> help"
    (is (= {:command :help}
           (cli/parse-args ["-h"]))))

  (testing "help alias"
    (is (= {:command :help}
           (cli/parse-args ["help"]))))

  (testing "unknown flag -> error"
    (let [result (cli/parse-args ["--unknown"])]
      (is (= :error (:command result)))
      (is (= "Unknown option: --unknown" (:message result)))))

  (testing "-n without name -> error"
    (is (= :error (:command (cli/parse-args ["-n"]))))))
