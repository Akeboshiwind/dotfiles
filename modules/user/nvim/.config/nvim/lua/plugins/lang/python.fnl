; plugins/lang/python.fnl

[{:mason/ensure-installed [:black :isort]
  :format/by-ft {:python [:black :isort]}
  :lsp/servers {:pylsp {}}}]
