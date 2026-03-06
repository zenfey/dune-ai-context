(* bin/dune_ai_context.ml
   Entry point for the executable. It now uses the Dune_ai_context library
   to parse Dune files and print the discovered vendor package dependencies.
*)

let () = Dune_ai_context.print_vendor_dependencies ()
