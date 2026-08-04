(ns version
  "Weigh the size of a version jump, so a plan can say which upgrades deserve
   a second look. Classification is positional — which component moved first —
   not semantic. That one rule reads calendar versions, brew revisions and
   four-component builds correctly without knowing they are any of those."
  (:require [clojure.string :as str]))

(defn- normalise
  "Strip a leading `v`. It is notation, not a component: `v1.9 → v2.0` has to
   compare 1 against 2, not `v1` against `v2`."
  [v]
  (str/replace v #"^v" ""))

(defn- components [v]
  (str/split (normalise v) #"[._-]"))

(defn- numeric [c]
  (when (and c (re-matches #"\d+" c))
    (parse-long c)))

(defn- first-difference
  "Index of the first component of `a` that `b` does not match, or nil when
   `b` matches all of them."
  [a b]
  (first (keep-indexed (fn [i c] (when (not= c (get b i)) i)) a)))

(defn severity
  "How loudly a jump from `from` to `to` should read.

     :major     the leading component moved up
     :downgrade any move backwards, at any depth — a pin that went the wrong
                way is worth as much attention as a major bump
     :minor     the second component moved up
     :patch     anything deeper, and any change that only lengthens a version
     :unknown   a leading move between things that are not both numbers —
                `latest`, a git sha, a codename. Not provably safe, so it is
                not treated as safe.

   Total: any pair of strings, or nil, lands somewhere."
  [from to]
  (if-not (and from to)
    :unknown
    (let [a (components from)
          b (components to)
          i (first-difference a b)]
      (if (nil? i)
        :patch
        (let [x (numeric (nth a i))
              y (numeric (get b i))]
          (cond
            (not (and x y)) (if (> i 1) :patch :unknown)
            (> x y)         :downgrade
            (zero? i)       :major
            (= 1 i)         :minor
            :else           :patch))))))

(defn change-index
  "Character index into `to` at which it first departs from `from`, so a reader
   can be shown the part that moved. Indexes the original string — a stripped
   `v` still has to be printed."
  [from to]
  (if-not (and from to)
    0
    (let [prefix (- (count to) (count (normalise to)))
          b      (components to)
          n      (count (take-while true? (map = (components from) b)))]
      ;; n components plus the n separators that follow them
      (min (count to)
           (+ prefix n (reduce + (map count (take n b))))))))
