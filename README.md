# dune‑ai‑context

`dune‑ai‑context` is a small OCaml command‑line tool that:

* Parses the external library dependencies of an OCaml project by invoking  
  `dune describe external‑lib‑deps`.
* Filters out `ppx_`‑prefixed packages (they are usually build‑time helpers).
* Looks for the compiled interface files (`.cmi`) of the remaining vendor
  libraries in the current OPAM switch (`$OPAM_SWITCH_PREFIX/lib`).
* Writes the interface signatures of each vendor library to
  `vendor_interfaces/<library>.mli` (one file per library).

The tool is useful when you need to inspect or export the public API of the
third‑party libraries used by a project.

## Installation

The project depends on the following OPAM packages:

* `dune` (≥ 3.21)
* `ocaml`
* `sexplib`
* `str`
* `unix`
* `compiler-libs.common`

You can install the tool directly from the repository:

