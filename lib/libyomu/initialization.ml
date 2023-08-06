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

open Util.FileSys

(** [create_yomu_share ()] create the folder [ $XDG_DATA_HOME/share/yomu] *)
let create_yomu_share () =
  create_folder ~on_error:(Error.Create_folder App.yomu_share) App.yomu_share

(** 
  [create_yomu_comic ()] create the folder [comic] in [$XDG_DATA_HOME/share/yomu] so 
  [$XDG_DATA_HOME/share/yomu/comics]
*)
let create_yomu_comics () =
  create_folder ~on_error:(Error.Create_folder App.yomu_comics) App.yomu_comics

(** [create_yomu_config ()] create the folder [ $XDG_CONFIG_HOME/yomu] *)
let create_yomu_config () =
  create_folder ~on_error:(Error.Create_folder App.yomu_comics) App.yomu_comics

(** 
  [create_yomu_hidden ()] create the folder [.scomics] in [$XDG_DATA_HOME/share/yomu] so 
  [$XDG_DATA_HOME/share/yomu/.scomics] and the file [.syomurc]
*)
let create_yomu_hidden ~key () =
  let ( let* ) = Result.bind in
  let* _ =
    create_folder ~on_error:(Error.Create_file App.yomu_hidden_comics)
      App.yomu_hidden_comics
  in
  let syomurc = Comic.Syomu.create in
  let encrypted = Comic.Syomu.encrypt ~key syomurc () in
  let* s =
    create_file
      ~on_file:(fun oc -> output_string oc encrypted)
      ~on_error:(Error.Create_file App.yomu_hidden_config)
      App.yomu_hidden_config
  in
  Ok s

let check_yomu_initialiaze () =
  match Sys.file_exists App.yomu_share with
  | true ->
      Ok ()
  | false ->
      Error App.yomu_share

let check_yomu_hidden () =
  let ( let* ) = Result.bind in
  let* () =
    match Sys.file_exists App.yomu_hidden_comics with
    | true ->
        Ok ()
    | false ->
        Error App.yomu_hidden_comics
  in
  let* () =
    match Sys.file_exists App.yomu_hidden_config with
    | true ->
        Ok ()
    | false ->
        Error App.yomu_hidden_config
  in
  Ok ()

let check_yomu_config () =
  let ( let* ) = Result.bind in
  let* () =
    match Sys.file_exists App.yomu_config with
    | true ->
        Ok ()
    | false ->
        Error App.yomu_comics
  in
  Ok ()

let read_config () =
  let content =
    match Sys.file_exists App.yomu_config_file with
    | true ->
        Util.Io.content_filename App.yomu_config_file ()
    | false ->
        let () = Out_channel.with_open_bin App.yomu_config_file ignore in
        String.empty
  in
  content |> String.split_on_char '\n'
  |> List.filter_map (fun line ->
         let splitter = String.split_on_char '=' line in
         match splitter with [ key; value ] -> Some (key, value) | _ -> None
     )
