(ns display
  "Terminal display utilities - colors and formatting"
  (:require [clojure.string :as str]
            [version :as v]))

;; =============================================================================
;; Colors
;; =============================================================================

(def ^:private GRAY "\033[90m")
(def ^:private GREEN "\033[32m")
(def ^:private RED "\033[31m")
(def ^:private YELLOW "\033[33m")
(def ^:private BOLD "\033[1m")
(def ^:private BOLD-RED "\033[1;31m")
(def ^:private RESET "\033[0m")

(defn gray "Wrap string in gray ANSI color." [s] (str GRAY s RESET))
(defn green "Wrap string in green ANSI color." [s] (str GREEN s RESET))
(defn red "Wrap string in red ANSI color." [s] (str RED s RESET))
(defn yellow "Wrap string in yellow ANSI color." [s] (str YELLOW s RESET))
(defn bold-red "Wrap string in bold red ANSI color." [s] (str BOLD-RED s RESET))
(defn bold "Wrap string in bold ANSI." [s] (str BOLD s RESET))

;; =============================================================================
;; Spinner
;; =============================================================================

(def ^:private spinner-frames ["⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"])

(def ^:private ticked?
  "True while a settled spinner line is the last thing printed, so
   end-spinner-block! knows whether there is a block to close."
  (atom false))

(defn- tty?
  "True when stdout is an interactive terminal."
  []
  (if-let [console (System/console)]
    ;; JDK 22+ hands out a Console even when redirected; isTerminal
    ;; disambiguates. Older runtimes only return a Console on a tty.
    (try (.isTerminal console)
         (catch Exception _ true))
    false))

(defn with-spinner*
  "Run thunk while animating a spinner beside message on the current line.
   Animates only on an interactive terminal; otherwise just runs the thunk.
   On success the line settles into a ticked, permanent line; if the thunk
   throws, the line is erased instead — a tick never claims failed work.
   Settled lines are grey throughout: they are a record of work already done,
   and the colours here are spent on the plan the reader came for."
  [message thunk]
  (if-not (tty?)
    (thunk)
    (let [spinning (atom true)
          animator (future
                     (loop [i 0]
                       (when @spinning
                         (print (str "\r" (nth spinner-frames (mod i (count spinner-frames))) " " message))
                         (flush)
                         (Thread/sleep 80)
                         (recur (inc i)))))
          erase! (fn []
                   (reset! spinning false)
                   @animator
                   (print "\r\033[K")
                   (flush))]
      (try
        (let [result (thunk)]
          (erase!)
          (println (gray (str "✓ " message)))
          (flush)
          (reset! ticked? true)
          result)
        (catch Throwable t
          (erase!)
          (throw t))))))

(defn end-spinner-block!
  "Close a run of ticked spinner lines with a blank line, so they read apart
   from whatever prints next. No-op unless a tick is the last thing on screen,
   which keeps a run that never spun (piped output, or a scope whose checks are
   all local) from opening with a stray blank line. Returns true when it printed,
   so a caller that was going to lead with a blank line anyway can skip its own."
  []
  (when (compare-and-set! ticked? true false)
    (println)
    (flush)
    true))

(defmacro with-spinner
  "Run body while showing message with an animated spinner (see with-spinner*)."
  [message & body]
  `(with-spinner* ~message (fn [] ~@body)))

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

(defn plan-heading
  "Open the plan body, set apart from whatever checking left on screen."
  []
  (end-spinner-block!)
  (println (bold "Plan")))

(def ^:private plan-icons
  {:installed  {:icon "✓" :color-fn green}
   :missing    {:icon "✗" :color-fn red}
   :outdated   {:icon "↑" :color-fn yellow}
   :wrong      {:icon "!" :color-fn red}
   :orphan     {:icon "⌫" :color-fn yellow}
   :unknown    {:icon "?" :color-fn gray}
   :error      {:icon "✗" :color-fn red}
   :cancelled  {:icon "⊘" :color-fn gray}})

(def ^:private jump-icons
  "An upgrade reads by weight: patch recedes, minor asks for a glance, major
   and any downgrade stop you. Shape carries the same signal as colour, so it
   survives a pipe or a reader who cannot see the red."
  {:major     {:icon "⇑" :color-fn bold-red}
   :downgrade {:icon "⇓" :color-fn bold-red}
   :minor     {:icon "↑" :color-fn yellow}
   :unknown   {:icon "↑" :color-fn yellow}
   :patch     {:icon "·" :color-fn gray}})

(defn- version-jump
  "Icon and colour for an outdated result that carries both versions, or nil
   when it carries none — a git ref that moved has no jump to weigh."
  [{:keys [state from to]}]
  (when (and (= :outdated state) from to)
    (jump-icons (v/severity from to))))

(defn- version-detail
  "Render `from → to` with only the part of `to` that moved picked out, so the
   line says where the version went without needing a legend."
  [from to color-fn]
  (let [i (v/change-index from to)
        moved (subs to i)]
    (str (gray (str from " → " (subs to 0 i)))
         (when (seq moved) (color-fn moved)))))

(defn render-plan-result [{:keys [label state detail instructions from to] :as result}]
  (let [jump (version-jump result)
        {:keys [icon color-fn]} (or jump (get plan-icons state (plan-icons :unknown)))
        line (cond
               jump   (str label "  " (version-detail from to color-fn))
               detail (str label (str "  " (gray detail)))
               :else  label)]
    (println " " (color-fn icon) line)
    (when (seq instructions)
      (doseq [instr instructions]
        (println "   " (gray instr))))))

(defn- jump-breakdown
  "Tally the outdated items worth a second look. Downgrades count as major and
   unprovable jumps count as minor — the same folding the icons do. Nil when
   every upgrade is a patch, so a quiet plan stays quiet."
  [jumps]
  (let [major (+ (get jumps :major 0) (get jumps :downgrade 0))
        minor (+ (get jumps :minor 0) (get jumps :unknown 0))
        parts (cond-> []
                (pos? major) (conj (bold-red (str major " major")))
                (pos? minor) (conj (yellow (str minor " minor"))))]
    (when (seq parts)
      (str (gray " (") (str/join (gray ", ") parts) (gray ")")))))

(defn plan-summary
  ([freq-map] (plan-summary freq-map {}))
  ([freq-map jumps]
   (let [parts (keep (fn [[state {:keys [color-fn]}]]
                      (when-let [n (get freq-map state)]
                        (str (color-fn (str n " " (name state)))
                             (when (= :outdated state) (jump-breakdown jumps)))))
                    [[:missing (plan-icons :missing)]
                     [:outdated (plan-icons :outdated)]
                     [:orphan (plan-icons :orphan)]
                     [:installed (plan-icons :installed)]
                     [:wrong (plan-icons :wrong)]
                     [:unknown (plan-icons :unknown)]
                     [:error (plan-icons :error)]
                     [:cancelled (plan-icons :cancelled)]])]
    ;; A plan with no body prints no heading, so this blank line is the one
    ;; closing the spinner block.
    (when-not (end-spinner-block!)
      (println))
    (println (str/join ", " parts)))))
