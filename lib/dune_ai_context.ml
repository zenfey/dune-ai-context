(* lib/dune_ai_context.ml
   This module provides functionality to parse Dune stanza files
   (bin/dune, lib/dune, test/dune) and extract the list of library dependencies.
   It then prints the dependencies, searches for the corresponding .cmi files
   in the OPAM_SWITCH_PREFIX/lib directory, and prints the paths of any found
   .cmi files.

   Missing Dune files are ignored, so the code works for projects that only
   have a lib, only have a bin, or have additional test stanzas.
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

(** [read_file_opt path] returns [Some content] if the file exists, otherwise [None]. *)
let read_file_opt (path : string) : string option =
  if Sys.file_exists path then Some (read_file path) else None

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

(** Recursively search for .cmi files named [target] under [dir]. *)
let rec find_cmi_files (dir : string) (target : string) : string list =
  try
    let entries = Sys.readdir dir in
    Array.fold_left
      (fun acc entry ->
         let path = Filename.concat dir entry in
         if Sys.is_directory path then
           acc @ find_cmi_files path target
         else if Filename.check_suffix entry ".cmi" then
           let base = Filename.chop_suffix entry ".cmi" in
           if base = target then path :: acc else acc
         else acc)
      [] entries
  with Sys_error _ -> []  (* directory does not exist or cannot be read *)

(** [print_vendor_dependencies ()] parses the project's Dune files (bin/dune,
    lib/dune, test/dune), extracts the library dependencies, deduplicates them,
    prints each dependency, then looks for the corresponding .cmi files in the
    OPAM_SWITCH_PREFIX/lib directory and prints any found paths. Missing files
    are silently ignored. *)
let print_vendor_dependencies () =
  let dune_files = [ "bin/dune"; "lib/dune"; "test/dune" ] in
  let deps =
    List.fold_left
      (fun acc path ->
         match read_file_opt path with
         | Some content -> extract_libraries content @ acc
         | None -> acc)
      [] dune_files
  in
  let uniq_deps = dedup deps in
  (* Print the vendor library names *)
  List.iter (printf "%s\n") uniq_deps;
  (* Locate and print .cmi files if OPAM_SWITCH_PREFIX is set *)
  match Sys.getenv_opt "OPAM_SWITCH_PREFIX" with
  | None -> ()
  | Some prefix ->
      let lib_dir = Filename.concat prefix "lib" in
      List.iter
        (fun dep ->
           let cmi_paths = find_cmi_files lib_dir dep in
           List.iter (fun p -> printf "CMI: %s\n" p) cmi_paths)
        uniq_deps
