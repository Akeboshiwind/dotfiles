(ns java-home-test
  (:require [clojure.test :refer [deftest testing is use-fixtures]]
            [babashka.fs :as fs]
            [babashka.process :as process]
            [clojure.string :as str]
            [actions :as a]
            [cache :as c]
            [actions.script]))

(def script "cfg/clojure/java-home.sh")

(def ^:dynamic *root* nil)

(use-fixtures :each
  (fn [f]
    (let [root (str (fs/create-temp-dir {:prefix "java-home-test-"}))]
      (binding [*root* root
                a/*cache* (atom {})]
        (try (f) (finally (fs/delete-tree root)))))))

(defn- installs [] (str *root* "/installs"))
(defn- vms [] (str *root* "/vms"))
(defn- env [] {"JAVA_INSTALLS_DIR" (installs) "JAVA_VM_DIR" (vms)})

(defn- install-jdk! [version]
  (fs/create-dirs (str (installs) "/" version "/Contents/Home")))

(defn- run! []
  (let [result (atom nil)]
    (with-out-str
      (reset! result (first (a/install! :pkg/script {} {:java-home {:path script :env (env)}} {}))))
    (:status @result)))

(defn- check? []
  (let [state (str *root* "/state")]
    (spit state (str/join (map #(str % "\n") (:state (c/get-script @a/*cache* "java-home")))))
    (zero? (:exit @(process/process ["bash" script "--check"]
                                    {:extra-env (assoc (env) "DOTFILES_SCRIPT_STATE" state)
                                     :out :string :err :string})))))

(defn- link [version] (str (vms) "/" version ".jdk/Contents"))

(defn- bundles [] (if (fs/exists? (vms)) (sort (map str (map fs/file-name (fs/list-dir (vms))))) []))

(deftest links-every-installed-jdk-test
  (install-jdk! "temurin-21.0.12")
  (install-jdk! "temurin-25.0.4")
  (fs/create-sym-link (str (installs) "/temurin-21") "temurin-21.0.12")

  (testing "unlinked JDKs are drift"
    (is (not (check?))))

  (testing "a run links each real install, skipping mise's alias symlinks"
    (is (= :ok (run!)))
    (is (= ["temurin-21.0.12.jdk" "temurin-25.0.4.jdk"] (bundles)))
    (is (= (str (installs) "/temurin-25.0.4/Contents")
           (str (fs/read-link (link "temurin-25.0.4")))))
    (is (check?)))

  (testing "the run records the versions it linked"
    (is (= ["temurin-21.0.12" "temurin-25.0.4"] (:state (c/get-script @a/*cache* "java-home"))))))

(deftest removes-links-for-uninstalled-jdks-test
  (install-jdk! "temurin-21.0.10")
  (install-jdk! "temurin-21.0.12")
  (run!)
  (fs/delete-tree (str (installs) "/temurin-21.0.10"))

  (testing "a link left by an uninstalled JDK is drift"
    (is (not (check?))))

  (testing "a run removes it and its bundle"
    (is (= :ok (run!)))
    (is (= ["temurin-21.0.12.jdk"] (bundles)))
    (is (= ["temurin-21.0.12"] (:state (c/get-script @a/*cache* "java-home"))))
    (is (check?))))

(deftest adopts-matching-links-test
  (install-jdk! "temurin-25.0.4")
  (fs/create-dirs (str (vms) "/temurin-25.0.4.jdk"))
  (fs/create-sym-link (link "temurin-25.0.4") (str (installs) "/temurin-25.0.4/Contents"))

  (testing "a link made by hand that matches is already satisfied"
    (is (check?)))

  (testing "a run takes it over, so it is cleaned up later"
    (is (= :ok (run!)))
    (is (= ["temurin-25.0.4"] (:state (c/get-script @a/*cache* "java-home"))))))

(deftest leaves-what-it-did-not-make-test
  (install-jdk! "temurin-21.0.12")
  (install-jdk! "temurin-25.0.4")
  (fs/create-dirs (str (vms) "/zulu-17.jdk/Contents"))
  (fs/create-dirs (link "temurin-25.0.4"))

  (testing "a bundle for something mise didn't install is untouched"
    (run!)
    (is (fs/directory? (str (vms) "/zulu-17.jdk/Contents"))))

  (testing "a real Contents where a link belongs fails the run rather than being replaced"
    (is (= :error (run!)))
    (is (fs/directory? (link "temurin-25.0.4")))
    (is (not (fs/sym-link? (link "temurin-25.0.4"))))))
