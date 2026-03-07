(* lib/dune_ai_context.ml
   This module provides functionality to parse Dune's external library
   dependencies using `dune describe external-lib-deps`. It extracts the
   `external_deps` field from the returned s‑expression, filters out any
   libraries whose names start with `ppx_`, and for each remaining vendor
   library writes its interface signature (obtained via `Cmi_format.read_cmi`)
   to a file `<vendor>.mli` inside the `vendor_interfaces` directory.
   The directory is created automatically if it does not exist.

   Missing Dune files are ignored, and the tool works for projects that have
   only a `lib`, only a `bin`, or additional `test` stanzas.
*)

open Printf
open Str
open Cmi_format
open Format
open Printtyp
open Sexplib.Sexp
open Unix

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

(** Ensure that a directory exists; create it if it does not. *)
let ensure_dir (dir : string) =
  if not (Sys.file_exists dir) then
    (* 0o755 = rwxr-xr-x *)
    Unix.mkdir dir 0o755

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
let extract_external_deps (sexp : t) : string list =
  let rec find_external = function
    | List (Atom "external_deps" :: List deps :: _) ->
        List.map
          (function
            | List (Atom name :: _) -> name
            | _ -> failwith "unexpected")
          deps
    | List l -> List.concat_map find_external l
    | Atom _ -> [] in
  find_external sexp

(** [vendor_deps ()] obtains the list of external vendor libraries, filtering out any
    that start with `ppx_`. *)
let vendor_deps () : string list =
  let output = run_dune_describe () in
  let sexp = of_string output in
  let deps = extract_external_deps sexp in
  List.filter (fun name -> not (String.length name >= 4 && String.sub name 0 4 = "ppx_")) deps

(** Write the interface signature of a library to `vendor_interfaces/<lib>.mli`. *)
let write_interface_to_file ~lib_name ~signature_str =
  let out_dir = "vendor_interfaces" in
  ensure_dir out_dir;
  let out_path = Filename.concat out_dir (lib_name ^ ".mli") in
  let oc = open_out out_path in
  output_string oc signature_str;
  close_out oc

(** [print_vendor_dependencies ()] processes each vendor library, extracts its
    `.cmi` signature, and writes it to a file under `vendor_interfaces`. *)
let print_vendor_dependencies () =
  let deps = vendor_deps () in
  match Sys.getenv_opt "OPAM_SWITCH_PREFIX" with
  | None ->
      (* No OPAM switch prefix – we cannot locate .cmi files, so do nothing. *)
      ()
  | Some prefix ->
      let lib_dir = Filename.concat prefix "lib" in
      List.iter
        (fun dep ->
           let cmi_paths = find_cmi_files lib_dir dep in
           match cmi_paths with
           | [] -> ()
           | paths ->
               (* Concatenate signatures from all found .cmi files. *)
               let signatures =
                 List.map
                   (fun p ->
                      let cmi = Cmi_format.read_cmi p in
                      asprintf "%a" Printtyp.signature cmi.cmi_sign)
                   paths
               in
               let combined = String.concat "\n\n" signatures in
               write_interface_to_file ~lib_name:dep ~signature_str:combined)
        deps
