(* lib/dune_ai_context.ml
   This module provides functionality to parse Dune's external library
   dependencies using `dune describe external-lib-deps`. It extracts the
   `external_deps` field from the returned s‑expression, filters out any
   libraries whose names start with `ppx_`, and for each remaining vendor
   library prints its name, the path(s) to its `.cmi` file(s) (found under
   `$OPAM_SWITCH_PREFIX/lib`), and the signature of each `.cmi` using
   `Printtyp.signature`.

   Missing Dune files are ignored, and the tool works for projects that have
   only a `lib`, only a `bin`, or additional `test` stanzas.
*)

open Printf
open Str
open Cmi_format
open Format
open Printtyp
open Sexplib.Sexp

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

(** [find_cmi_files dir target] recursively searches for `.cmi` files named [target] under [dir]. *)
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

(** [run_dune_describe ()] runs `dune describe external-lib-deps` and returns its output as a string. *)
let run_dune_describe () : string =
  let ic = Unix.open_process_in "dune describe external-lib-deps" in
  let buf = Buffer.create 4096 in
  (try
     while true do
       Buffer.add_string buf (input_line ic);
       Buffer.add_char buf '\n'
     done
   with End_of_file -> ());
  let _ = Unix.close_process_in ic in
  Buffer.contents buf

(** [extract_external_deps sexp] walks the s‑expression returned by `dune describe`
    and returns a list of library names appearing in the `external_deps` field. *)
let rec extract_external_deps (sexp : t) : string list =
  match sexp with
  | List (_default :: libs) ->
      (* `libs` is a list of library specifications *)
      List.concat_map
        (function
          | List fields ->
              (* Find the field whose first atom is "external_deps" *)
              (match List.find_opt
                       (function
                         | List (Atom "external_deps" :: _) -> true
                         | _ -> false)
                       fields with
               | Some (List (_atom :: deps)) ->
                   (* `deps` is a list like ((core required) (str required) ...) *)
                   List.fold_left
                     (fun acc -> function
                       | List [Atom name; _required] -> name :: acc
                       | _ -> acc)
                     [] deps
               | _ -> [])
          | _ -> [])
        libs
  | _ -> []

(** [vendor_deps ()] obtains the list of external vendor libraries, filtering out any
    that start with `ppx_`. *)
let vendor_deps () : string list =
  let output = run_dune_describe () in
  let sexp = of_string output in
  let deps = extract_external_deps sexp in
  List.filter (fun name -> not (String.length name >= 4 && String.sub name 0 4 = "ppx_")) deps

(** [print_vendor_dependencies ()] prints each vendor library, the path(s) to its
    `.cmi` file(s) and the signature of each `.cmi`. *)
let print_vendor_dependencies () =
  let deps = vendor_deps () in
  match Sys.getenv_opt "OPAM_SWITCH_PREFIX" with
  | None ->
      (* No OPAM switch prefix – just print the library names *)
      List.iter (printf "%s\n") deps
  | Some prefix ->
      let lib_dir = Filename.concat prefix "lib" in
      List.iter
        (fun dep ->
           let cmi_paths = find_cmi_files lib_dir dep in
           if cmi_paths = [] then
             (* No .cmi found – print only the library name *)
             printf "%s\n" dep
           else
             (* For each .cmi, print library name, path, and the signature *)
             List.iter
               (fun p ->
                  let cmi = Cmi_format.read_cmi p in
                  printf "%s %s\n" dep p;
                  Format.printf "%a\n" Printtyp.signature cmi.cmi_sign)
               cmi_paths)
        deps
