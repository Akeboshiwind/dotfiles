(local map vim.keymap.set)

;;; Editing -------------------------------------------------------------------

(map :i :fd :<ESC> { :desc "Quick Escape"})
(map :n :<leader>fy "<cmd>Telescope filetypes<cr>" { :desc "Set filetype"})

;;; Git hunks -----------------------------------------------------------------

(fn selected-lines []
  "Ascending, because stage_hunk only documents a range, not an orientation."
  (let [cursor (vim.fn.line ".")
        anchor (vim.fn.line "v")]
    [(math.min cursor anchor) (math.max cursor anchor)]))

(fn map-hunk [key action desc]
  "Normal mode acts on the hunk under the cursor, visual mode on the selection —
  separate maps so the visual one can never be reached without a range."
  (map :n key
       (fn [] ((. (require :gitsigns) action)))
       {:desc desc})
  (map :x key
       (fn [] ((. (require :gitsigns) action) (selected-lines)))
       {:desc (.. desc " (selection)")}))

(map-hunk :<leader>hs :stage_hunk "Stage hunk")
(map-hunk :<leader>hr :reset_hunk "Reset hunk")

(map :n :<leader>hp
     (fn [] (let [gitsigns (require :gitsigns)] (gitsigns.preview_hunk)))
     {:desc "Preview hunk"})

;; Both toggles are global gitsigns config, so drive word-diff from whatever
;; show_deleted just became — they can never end up disagreeing.
(map :n :<leader>ho
     (fn []
       (let [gitsigns (require :gitsigns)
             on? (gitsigns.toggle_deleted)]
         (gitsigns.toggle_word_diff on?)))
     {:desc "Toggle diff overlay"})
