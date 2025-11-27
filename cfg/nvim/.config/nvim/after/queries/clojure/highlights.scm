; extends

; deftest - (deftest name & body)
; Matches both deftest and t/deftest
(list_lit
  value: (sym_lit
    name: (sym_name) @_keyword)
  (#eq? @_keyword "deftest")
  value: (sym_lit) @AlabasterDefinition)

; defmulti - (defmulti name dispatch-fn & options)
(list_lit
  value: (sym_lit
    name: (sym_name) @_keyword)
  (#eq? @_keyword "defmulti")
  value: (sym_lit) @AlabasterDefinition)

; defmethod - (defmethod multifn dispatch-val & body)
(list_lit
  value: (sym_lit
    name: (sym_name) @_keyword)
  (#eq? @_keyword "defmethod")
  value: (sym_lit) @AlabasterDefinition)

; defrecord - (defrecord Name [fields] & body)
(list_lit
  value: (sym_lit
    name: (sym_name) @_keyword)
  (#eq? @_keyword "defrecord")
  value: (sym_lit) @AlabasterDefinition
  value: (vec_lit))

; deftype - (deftype Name [fields] & body)
(list_lit
  value: (sym_lit
    name: (sym_name) @_keyword)
  (#eq? @_keyword "deftype")
  value: (sym_lit) @AlabasterDefinition
  value: (vec_lit))

; defprotocol - (defprotocol Name & methods)
(list_lit
  value: (sym_lit
    name: (sym_name) @_keyword)
  (#eq? @_keyword "defprotocol")
  value: (sym_lit) @AlabasterDefinition)

; def - (def name value)
(list_lit
  value: (sym_lit
    name: (sym_name) @_keyword)
  (#eq? @_keyword "def")
  value: (sym_lit) @AlabasterDefinition)

; defonce - (defonce name value)
(list_lit
  value: (sym_lit
    name: (sym_name) @_keyword)
  (#eq? @_keyword "defonce")
  value: (sym_lit) @AlabasterDefinition)
