(ns display
  "Terminal display utilities - colors and formatting"
  (:require [clojure.string :as str]))

;; =============================================================================
;; Colors
;; =============================================================================

(def ^:private GRAY "\033[90m")
(def ^:private GREEN "\033[32m")
(def ^:private RED "\033[31m")
(def ^:private YELLOW "\033[33m")
(def ^:private RESET "\033[0m")

(defn gray "Wrap string in gray ANSI color." [s] (str GRAY s RESET))
(defn green "Wrap string in green ANSI color." [s] (str GREEN s RESET))
(defn red "Wrap string in red ANSI color." [s] (str RED s RESET))
(defn yellow "Wrap string in yellow ANSI color." [s] (str YELLOW s RESET))

;; =============================================================================
;; Section formatting
;; =============================================================================

(defn render-result [{:keys [label status message detail]}]
  (let [icon (case status
               :ok (green "✓")
               :skip (gray "·")
               :error (red "✗"))
        msg (case status
              :ok (if message (str label " " (gray message)) label)
              :skip (gray (str label " " (or message "skipped")))
              :error (if message (str label " " (red message)) label))]
    (println " " icon msg)
    (when (seq detail)
      (doseq [line detail]
        (println "   " (gray line))))))

(defn section
  "Print a section with title and render results.
   Results are maps with :label, :status (:ok/:skip/:error), and optional :message.
   Returns the results as a vector."
  [title results]
  (println title)
  (reduce (fn [acc result]
            (render-result result)
            (conj acc result))
          [] results))

;; =============================================================================
;; Plan display
;; =============================================================================

(def ^:private plan-icons
  {:installed {:icon "✓" :color-fn green}
   :missing   {:icon "✗" :color-fn red}
   :outdated  {:icon "↑" :color-fn yellow}
   :wrong     {:icon "!" :color-fn red}
   :unknown   {:icon "?" :color-fn gray}})

(defn render-plan-result [{:keys [label state detail]}]
  (let [{:keys [icon color-fn]} (get plan-icons state (plan-icons :unknown))
        line (if detail
               (str label (str "  " (gray detail)))
               label)]
    (println " " (color-fn icon) line)))

(defn plan-summary [freq-map]
  (let [parts (keep (fn [[state {:keys [color-fn]}]]
                      (when-let [n (get freq-map state)]
                        (color-fn (str n " " (name state)))))
                    [[:missing (plan-icons :missing)]
                     [:outdated (plan-icons :outdated)]
                     [:installed (plan-icons :installed)]
                     [:wrong (plan-icons :wrong)]
                     [:unknown (plan-icons :unknown)]])]
    (println)
    (println (str/join ", " parts))))
