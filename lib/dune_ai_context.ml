(* lib/dune_ai_context.ml
   This module provides functionality to parse Dune stanza files
   (bin/dune and lib/dune) and extract the list of library dependencies.
   It then prints those dependencies to the standard output.

   The parsing is intentionally simple: it looks for the "(libraries ...)"
   stanza and extracts the identifiers inside the parentheses.
*)

open Printf
open Str

(** [read_file path] reads the whole content of the file at [path] and returns it as a string. *)
let read_file (path : string) : string =
  let ic = open_in path in
  let len = in_channel_length ic in
  let content = really_input_string ic len in
  close_in ic;
  content

(** [extract_libraries content] returns a list of library names found in a Dune file
    content. It searches for occurrences of "(libraries ...)" and splits the
    identifiers by whitespace. *)
let extract_libraries (content : string) : string list =
  let rec aux pos acc =
    try
      (* Find the next opening parenthesis *)
      let open_paren = String.index_from content pos '(' in
      (* Check if this is a "(libraries" stanza *)
      if String.length content >= open_paren + 10
         && String.sub content open_paren 10 = "(libraries"
      then
        (* Find the matching closing parenthesis for this stanza *)
        let close_paren = String.index_from content (open_paren + 1) ')' in
        let inside =
          String.sub content (open_paren + 10) (close_paren - (open_paren + 10))
        in
        let libs =
          split (regexp "[ \t\r\n]+") (String.trim inside)
        in
        aux (close_paren + 1) (libs @ acc)
      else aux (open_paren + 1) acc
    with Not_found -> acc
  in
  aux 0 []

(** [dedup lst] removes duplicate entries from a list while preserving order. *)
let dedup (lst : string list) : string list =
  let tbl = Hashtbl.create (List.length lst) in
  List.filter
    (fun x ->
       if Hashtbl.mem tbl x then false
       else (Hashtbl.add tbl x (); true))
    lst

(** [print_vendor_dependencies ()] parses the project's bin/dune and lib/dune files,
    extracts the library dependencies, deduplicates them, and prints each one
    on its own line. *)
let print_vendor_dependencies () =
  let bin_dune = "bin/dune" in
  let lib_dune = "lib/dune" in
  let bin_content = read_file bin_dune in
  let lib_content = read_file lib_dune in
  let deps = extract_libraries bin_content @ extract_libraries lib_content in
  let uniq_deps = dedup deps in
  List.iter (printf "%s\n") uniq_deps
