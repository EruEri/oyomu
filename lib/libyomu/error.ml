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

type init_error =
  | App_folder_already_exist of string
  | Create_folder of string
  | Create_file of string
  | EncryptionError of string

type rename_error =
  | Comic_not_exist of string
  | Comic_already_exist of string
  | Complicting_volume of {
      oldname : string;
      newname : string;
      conflits : string list;
    }

type error =
  | No_Option_choosen
  | No_file_to_decrypt
  | Yomu_Not_Initialized
  | YomuCreateConfigError
  | DecryptionError of string
  | Already_Existing_name of string
  | Volume_already_existing of { comic : string; volume : int }
  | Missing_file of { true_name : string; encrypted_name : string }
  | Missing_init_file of string
  | Init_Error of init_error
  | Rename_Error of rename_error
  | Non_existing_group of string list

let string_of_init_error = function
  | App_folder_already_exist path ->
      Printf.sprintf "\"%s\" directory already exists" path
  | Create_folder path ->
      Printf.sprintf "Unable to create directory : %s" path
  | Create_file path ->
      Printf.sprintf "Unable to create file : %s" path
  | EncryptionError path ->
      Printf.sprintf "Unable to encrypt file : %s" path

let string_of_rename_error = function
  | Comic_not_exist s ->
      Printf.sprintf "Comic \"%s\" doesn't exist" s
  | Comic_already_exist s ->
      Printf.sprintf "Comic \"%s\" already exists" s
  | Complicting_volume { oldname; newname; conflits } ->
      Printf.sprintf
        "Cannot merge %s into %s since the following volume conflit:\n\t-%s"
        oldname newname
      @@ String.concat "\n\t-" conflits

let string_of_error = function
  | Yomu_Not_Initialized ->
      Printf.sprintf
        "\"yomu\" directory doesn't exist. Use oyomu init to initialize"
  | YomuCreateConfigError ->
      Printf.sprintf "Unable to create/read the file : %s"
      @@ Config.yomu_config_file
  | No_Option_choosen ->
      "Operation Aborted"
  | Missing_init_file file ->
      Printf.sprintf "The file \"%s\" is missing" file
  | No_file_to_decrypt ->
      Printf.sprintf "No File to decrypt"
  | Volume_already_existing { comic; volume } ->
      Printf.sprintf "Comic \"%s\": the volume %u already exists" comic volume
  | DecryptionError file ->
      Printf.sprintf "decrptytion error : %s" file
  | Already_Existing_name filename ->
      Printf.sprintf "Filename : \"%s\" is already in hisoka" filename
  | Missing_file { true_name; encrypted_name } ->
      Printf.sprintf "Filename: \"%s\" is missing: This file encrypted: \"%s\""
        encrypted_name true_name
  | Init_Error init ->
      string_of_init_error init
  | Rename_Error ri ->
      string_of_rename_error ri
  | Non_existing_group groups ->
      let s, does =
        match groups with [] | _ :: [] -> ("", "doesn't") | _ -> ("s", "don't")
      in
      Printf.sprintf "The following group%s %s exist: [%s]" s does
        (String.concat ", " groups)

exception YomuError of error

let yomu_error e = YomuError e

let register_exn () =
  Printexc.register_printer (function
    | YomuError error ->
        error |> string_of_error |> Option.some
    | _ ->
        None
    )

let emit_warning s = ignore s
let register_exn = register_exn ()
