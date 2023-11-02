(**********************************************************************************************)
(*                                                                                            *)
(* This file is part of Yomu: A comic reader                                                  *)
(* Copyright (C) 2023 Yves Ndiaye                                                             *)
(*                                                                                            *)
(* Yomu is free software: you can redistribute it and/or modify it under the terms            *)
(* of the GNU General Public License as published by the Free Software Foundation,            *)
(* either version 3 of the License, or (at your option) any later version.                    *)
(*                                                                                            *)
(* Yomu is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;          *)
(* without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR           *)
(* PURPOSE.  See the GNU General Public License for more details.                             *)
(* You should have received a copy of the GNU General Public License along with Yomu.         *)
(* If not, see <http://www.gnu.org/licenses/>.                                                *)
(*                                                                                            *)
(**********************************************************************************************)

module Hash = struct
  let hash_name ~name ~extension =
    let extension =
      if extension = String.empty then
        String.empty
      else
        "." ^ extension
    in
    let hash_name = name ^ extension |> Digest.string |> Digest.to_hex in
    Printf.sprintf "%s" hash_name

  let rec generate_unique_name ?(max_iter = 5) ~extension ~name path =
    let ( // ) = Filename.concat in
    if max_iter <= 0 then
      None
    else
      let hashed_name = hash_name ~name ~extension in
      let file_full_path = path // hashed_name in
      if not @@ Sys.file_exists file_full_path then
        Some hashed_name
      else
        generate_unique_name ~max_iter:(max_iter - 1) ~name:hashed_name
          ~extension path
end

module FileSys = struct
  let create_folder ?(perm = 0o700) ~on_error folder =
    let to_path_string = folder in
    match Sys.file_exists to_path_string with
    | true ->
        Ok to_path_string
    | false ->
        let r =
          match Sys.mkdir to_path_string perm with
          | exception _ ->
              Error on_error
          | () ->
              Ok folder
        in
        r

  let create_file ?(on_file = fun _ -> ()) ~on_error file =
    let to_file_path = file in
    match Out_channel.open_bin to_file_path with
    | exception _ ->
        Error on_error
    | outchan ->
        let () = on_file outchan in
        let () = close_out outchan in
        Ok file

  let rec rmrf path () =
    match Sys.is_directory path with
    | true ->
        let () =
          Sys.readdir path
          |> Array.iter (fun name -> rmrf (Filename.concat path name) ())
        in
        Unix.rmdir path
    | false ->
        Sys.remove path
    | exception e ->
        raise e
end

module Io = struct
  let read_file ch () = really_input_string ch (in_channel_length ch)

  let content_filename string () =
    In_channel.with_open_bin string (fun ic -> read_file ic ())

  let cp input output =
    let content = In_channel.with_open_bin input (fun ic -> read_file ic ()) in
    Out_channel.with_open_bin output (fun oc ->
        Out_channel.output_string oc content
    )

  let dump_tmp ~name ~extension content () =
    let filename, outchan = Filename.open_temp_file name extension in
    let () = output_string outchan content in
    let () = close_out outchan in
    filename
end

module AsciiString = struct
  let bold_sseq = "\u{001B}[1m"
  let bold_eseq = "\u{001B}[22m"
  let bold s = Printf.sprintf "%s%s%s" bold_sseq s bold_eseq
end

module UString = struct
  let keep_n n s =
    let l = String.length s in
    match n >= l with true -> s | false -> String.sub s 0 (l + (n - l))
end

module Ulist = struct
  let rec map_ok f = function
    | [] ->
        Result.ok []
    | t :: q ->
        let ( let* ) = Result.bind in
        let* res = f t in
        let* list = map_ok f q in
        Result.ok @@ (res :: list)

  let rec map_some f = function
    | [] ->
        Option.some []
    | t :: q ->
        let ( let* ) = Option.bind in
        let* res = f t in
        let* list = map_some f q in
        Option.some @@ (res :: list)

  let rec fold_some f acc = function
    | [] ->
        Option.some acc
    | t :: q ->
        let ( let* ) = Option.bind in
        let* acc = f acc t in
        fold_some f acc q

  let rec fold_ok f acc = function
    | [] ->
        Result.ok acc
    | t :: q ->
        let ( let* ) = Result.bind in
        let* acc = f acc t in
        fold_ok f acc q
end

module Axe = struct
  type t = AxeX | AxeY

  let to_string ?(uppercase = true) elt =
    let transform =
      if uppercase then
        String.capitalize_ascii
      else
        Fun.id
    in
    let s = match elt with AxeX -> "x" | AxeY -> "y" in
    transform s
end
