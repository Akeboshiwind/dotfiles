; util/set.fnl

; >> Simple set implementation
;
; Uses a table as a set with the keys as values:
;
; # Insertion:
; (tset set value true)
;
; # Contains?
; (if (. set value)
;   (print "contains"))
;
; See: https://www.lua.org/pil/11.5.html

(lambda new []
  "Create a new set"
  [])

(fn contains? [s v]
  "Test if the set contains the value"
  (. s v))

(fn insert! [s v]
  "Insert the value into the set"
  (tset s v true))

(fn remove! [s v]
  "Remove the value from the set"
  (tset s v nil))

{: new
 : contains?
 : insert!
 : remove!}
