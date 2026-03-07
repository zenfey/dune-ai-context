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
third‑party libraries used in a project, and when you want to give AI coding
assistants full visibility of those APIs without requiring them to resolve
external dependencies themselves.

## Installation

The project depends on the following OPAM packages:

* `dune` (≥ 3.1)
* `ocaml`
* `sexplib`
* `str`
* `unix`
* `compiler-libs.common`

You can install the tool directly from the repository:

```sh
git clone https://github.com/zenfey/dune-ai-context
cd dune-ai-context
opam pin add dune-ai-context .
opam install dune-ai-context
```

## Building from source

If you prefer to build manually with `dune`:

```sh
dune build
```

The executable will be built as `_build/default/bin/dune_ai_context.exe`
(and installed as `dune-ai-context` when you run `dune install`).

## Usage

Assuming your OCaml project that uses Dune is located at `<proj-root>`:

* Run the tool from the project root:

```sh
cd <proj-root>
dune-ai-context
```

* Or invoke it with the project directory as an argument:

```sh
dune-ai-context <proj-root>
```

The command will create a `vendor_interfaces` directory inside the current
working directory (or inside `<proj-root>` if you passed it as an argument) and
populate it with `<library>.mli` files containing the exported signatures.

### Environment variable

`dune‑ai‑context` relies on the `OPAM_SWITCH_PREFIX` environment variable to
locate the compiled libraries. Ensure it is set (it is automatically set when
you are inside an OPAM switch). If the variable is not present the tool will
skip the `.cmi` lookup.

## Testing

The project includes an inline test for the `extract_external_deps` function
using `ppx_inline_test`. Run the tests with:

```sh
dune runtest
```

## License

MIT – see the `LICENSE` file for details.

## Contributing

Feel free to open issues or submit pull requests on the GitHub repository:

<https://github.com/zenfey/dune-ai-context>


