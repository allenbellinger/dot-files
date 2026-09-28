; extends

; SQL highlighting for Spring Data @Query strings. SQL is used for both native
; SQL and JPQL. Keep nvim-treesitter's default Java injections via extends.

; Positional @Query("...") arguments.
((annotation
  name: (identifier) @_annotation
  arguments: (annotation_argument_list
    (string_literal
      .
      (_) @injection.content)))
  (#eq? @_annotation "Query")
  (#set! injection.language "sql"))

; Named @Query(value = "...") arguments.
((annotation
  name: (identifier) @_annotation
  arguments: (annotation_argument_list
    (element_value_pair
      key: ((identifier) @_key
        (#eq? @_key "value"))
      value: (string_literal
        .
        (_) @injection.content))))
  (#eq? @_annotation "Query")
  (#set! injection.language "sql"))
