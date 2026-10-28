(fn realpath [path]
  (or (vim.uv.fs_realpath path) path))

(fn list []
  "The live Claude agents, as `claude agents --json` rows with `cwd` resolved through symlinks.
  Empty when `claude agents` fails."
  (let [(ran? result) (pcall #(: (vim.system [:claude :agents :--json] {:text true}) :wait 2000))
        (parsed? rows) (if (and ran? (= 0 result.code))
                           (pcall vim.json.decode result.stdout)
                           false)]
    (if parsed?
        (icollect [_ row (ipairs rows)]
          (doto row (tset :cwd (realpath row.cwd))))
        [])))

{: list}
