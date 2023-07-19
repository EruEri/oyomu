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
    match Sys.mkdir to_path_string perm with
    | exception _ ->
        Error on_error
    | () ->
        Ok folder

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
        Sys.readdir path
        |> Array.iter (fun name -> rmrf (Filename.concat path name) ());
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
end
