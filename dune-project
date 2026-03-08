(lang dune 3.1)

(name dune-ai-context)

(generate_opam_files true)

(source
 (github zenfey/dune-ai-context))

(authors "ZFY <zf.yuan.y@gmail.com>")
(maintainers "ZFY <zf.yuan.y@gmail.com>")

(license MIT)

(documentation "https://github.com/zenfey/dune-ai-context")

(package
 (name dune-ai-context)
 (synopsis "Extract dune external dependencies and generate interface context for AI tools")
 (description "dune-ai-context parses external library dependencies using `dune describe external-lib-deps`, finds their `.cmi` files, and writes interface signatures for AI-assisted coding tools.")
 (depends
  (ocaml (>= 4.14))
  (dune (>= 3.1))
  sexplib
  str
  unix)
 (tags
  ("ocaml" "dune" "cmi" "interfaces" "ai")))