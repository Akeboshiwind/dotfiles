(ns display
  "Terminal display utilities - colors and formatting")

;; =============================================================================
;; Colors
;; =============================================================================

(def ^:private GRAY "\033[90m")
(def ^:private GREEN "\033[32m")
(def ^:private RED "\033[31m")
(def ^:private RESET "\033[0m")

(defn gray "Wrap string in gray ANSI color." [s] (str GRAY s RESET))
(defn green "Wrap string in green ANSI color." [s] (str GREEN s RESET))
(defn red "Wrap string in red ANSI color." [s] (str RED s RESET))

;; =============================================================================
;; Section formatting
;; =============================================================================

(defn- render-result [{:keys [label status message]}]
  (let [icon (case status
               :ok (green "✓")
               :skip (gray "·")
               :error (red "✗"))
        msg (case status
              :ok (if message (str label " " (gray message)) label)
              :skip (gray (str label " " (or message "skipped")))
              :error (if message (str label " " (red message)) label))]
    (println " " icon msg)))

(defn section
  "Print a section with title and render results.
   Results are maps with :label, :status (:ok/:skip/:error), and optional :message"
  [title results]
  (println title)
  (doseq [result results]
    (render-result result)))
