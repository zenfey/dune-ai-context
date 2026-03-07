(lang dune 3.1)

(name dune-ai-context)

(generate_opam_files true)

(source
 (github zenfey/dune-ai-context))

(authors "ZFY <zf.yuan.y@gmail.com>")

(maintainers "ZFY <zf.yuan.y@gmail.com>")

(license "MIT")

(documentation "https://github.com/zenfey/dune-ai-context")

(package
 (name dune-ai-context)
 (synopsis "Tool to extract vendor library dependencies from Dune files and generate .mli interface files from their .cmi files.")
 (description "dune-ai-context parses the external library dependencies of an OCaml project using `dune describe external-lib-deps`, filters out `ppx_` packages, locates the corresponding `.cmi` files in the OPAM switch, and writes their interface signatures to `vendor_interfaces/<library>.mli`. This provides a convenient context for AI‑assisted coding tools.")
 (depends ocaml (dune (>= 3.1)) sexplib str unix compiler-libs.common)
 (tags
  ("ocaml" "dune" "vendor" "cmi" "interface" "AI tool" "LLM")))
