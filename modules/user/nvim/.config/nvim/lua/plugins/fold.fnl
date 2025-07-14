; plugins/fold.fnl
(local {: autoload} (require :nfnl.module))
(local {: get : concat} (autoload :nfnl.core))
(local ufo (autoload :ufo))
(local ts-provider (autoload :ufo.provider.treesitter))
(local foldingrange (autoload :ufo.model.foldingrange))

(local ft->query
  {:typescript
   "(call_expression
      function: (identifier) @_fn
      (#match? @_fn \"^(test|it|beforeEach|afterEach)$\")) @fold.test

    [(function_declaration)
     (method_definition)
     (generator_function_declaration)] @fold.custom"
   :yaml
   "(block_mapping_pair
      key: (_ (_ (string_scalar) @service_key))
      value: (_ (_ (block_mapping_pair) @fold.custom))
      (#eq? @service_key \"services\"))"
   :clojure
   "(list_lit
      . (sym_lit name: (sym_name) @_fn)
      (#match? @_fn \"^(deftest-?|use-fixtures|defn-?|defmethod|defmacro)$\")) @fold.custom"})

(comment
  ; Load up fold.lua and use ,x to run this
  (do
    (each [ft query (pairs ft->query)]
      (vim.treesitter.query.parse ft query))
    (print "Success! 🎉")))

(fn query-folds [bufnr ft->query]
  (let [ft (vim.api.nvim_get_option_value :filetype {:buf bufnr})
        query-str (get ft->query ft)
        (_ parser) (pcall vim.treesitter.get_parser bufnr ft)]
    (when (and query-str parser)
      (let [[tree] (parser:parse)
            root (tree:root)
            (ok query) (pcall vim.treesitter.query.parse ft query-str)]
        (if (not ok)
          (do
            (vim.notify (.. "Error parsing custom query for " ft)
                        vim.log.levels.ERROR)
            nil)
          (let [tbl []]
            (each [id node (query:iter_captures root bufnr)]
              (let [capture-name (. query.captures id)
                    (start _ stop stop-col) (node:range)
                    stop (if (= stop-col 0) (- stop 1) stop)]
                (when (> stop start)
                  (table.insert tbl (foldingrange.new start stop nil nil capture-name)))))
            tbl))))))

(fn treesitter+queries [ft->query]
  (fn [bufnr]
    (let [ranges (concat []
                         (ts-provider.getFolds bufnr)
                         (query-folds bufnr ft->query))]
      (foldingrange.sortRanges ranges)
      ranges)))

[{1 :kevinhwang91/nvim-ufo
  :dependencies [:kevinhwang91/promise-async]
  :lazy false
  :config (fn []
            (set vim.opt.foldenable true)

            ;; How folds look
            (set vim.opt.foldcolumn "0") ; disable
            ;(set vim.opt.foldtext "") ; show the first line syntax highlighted
            ;; How folds work
            (set vim.opt.foldlevel 99) ; Let ufo control closing
            (set vim.opt.foldlevelstart 99) ; Let ufo control closing
            ;(set vim.opt.foldnestmax 4) ; max nesting
            (set vim.opt.foldopen "") ; disable vim auto-opening folds (e.g. '[' and search)

            (ufo.setup
              {:provider_selector
               (fn [_bufnr _filetype _buftype]
                 [(treesitter+queries ft->query)
                  :indent])
               :open_fold_hl_timeout 100
               :close_fold_kinds_for_ft
               {:default [:fold.custom :fold.test]}}))
  :keys [{1 "zR" 2 #(ufo.openAllFolds)
          :mode [:n]
          :desc "Open All Folds"}
         {1 "zM" 2 #(ufo.closeAllFolds)
          :mode [:n]
          :desc "Close All Folds"}]}]
