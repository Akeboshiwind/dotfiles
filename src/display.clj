(ns display
  "Terminal display utilities - colors and formatting")

(def ^:private GRAY "\033[90m")
(def ^:private GREEN "\033[32m")
(def ^:private RED "\033[31m")
(def ^:private RESET "\033[0m")

(defn gray [s] (str GRAY s RESET))
(defn green [s] (str GREEN s RESET))
(defn red [s] (str RED s RESET))
