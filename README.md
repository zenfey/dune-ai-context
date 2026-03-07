# dune‑ai‑context

`dune‑ai‑context` is a small OCaml command‑line tool that:

* Parses the external library dependencies of an OCaml project by invoking  
  `dune describe external‑lib‑deps`.
* Filters out `ppx_`‑prefixed packages (they are usually build‑time helpers).
* Looks for the compiled interface files (`.cmi`) of the remaining vendor
  libraries in the current OPAM switch (`$OPAM_SWITCH_PREFIX/lib`).
* **Collects the public API of all third‑party libraries and writes each
  interface to `vendor_interfaces/<library>.mli`.**  
  The generated `vendor_interfaces` directory can be added to a project's
  source tree and used as a *context* for AI‑assisted coding tools such as
  Claude Code, OpenCode, Aider, and similar assistants that can read local
  files to provide more accurate suggestions.

The tool is useful when you need to inspect or export the public API of the
third‑party libraries used by a project, and when you want to give AI coding
assistants full visibility of those APIs without requiring them to resolve
external dependencies themselves.

## Installation

The project depends on the following OPAM packages:

* `dune` (≥ 3.21)
* `ocaml`
* `sexplib`
* `str`
* `unix`
* `compiler-libs.common`

You can install the tool directly from the repository:

