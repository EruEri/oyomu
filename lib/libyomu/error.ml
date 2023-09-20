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
  | AppFolderAlreadyExist of string
  | CreateFolder of string
  | CreateFile of string
  | EncryptionError of string

type rename_error =
  | ComicNotExist of string
  | ComicAlreadyExist of string
  | ConflictingVolume of {
      oldname : string;
      newname : string;
      conflits : string list;
    }

type epub_error =
  | UnknownError of (int * int)
  | TooMuchValueForTag of { tag : string }
  | MissingMendatoryKey of { section : string; key : string }
  | MissingAttributes of { attribut : string }
  | WrongExpectedTag of string

type error =
  | NoOptionChoosen
  | NoFileToDecrypt
  | YomuNotInitialized
  | YomuCreateConfigError
  | DecryptionError of string
  | AlreadyExistingName of string
  | VolumeAlreadyExisting of { comic : string; volume : int }
  | MissingFile of { true_name : string; encrypted_name : string }
  | MissingInitFile of string
  | InitError of init_error
  | RenameError of rename_error
  | EpubError of epub_error
  | NonExistingGroup of string list

let string_of_init_error = function
  | AppFolderAlreadyExist path ->
      Printf.sprintf "\"%s\" directory already exists" path
  | CreateFolder path ->
      Printf.sprintf "Unable to create directory : %s" path
  | CreateFile path ->
      Printf.sprintf "Unable to create file : %s" path
  | EncryptionError path ->
      Printf.sprintf "Unable to encrypt file : %s" path

let string_of_rename_error = function
  | ComicNotExist s ->
      Printf.sprintf "Comic \"%s\" doesn't exist" s
  | ComicAlreadyExist s ->
      Printf.sprintf "Comic \"%s\" already exists" s
  | ConflictingVolume { oldname; newname; conflits } ->
      Printf.sprintf
        "Cannot merge %s into %s since the following volume conflit:\n\t-%s"
        oldname newname
      @@ String.concat "\n\t-" conflits

let string_of_epub_error =
  let open Printf in
  function
  | UnknownError (i, o) ->
      Printf.sprintf "Loc error %u %u" i o
  | MissingMendatoryKey { section; key } ->
      sprintf "\"%s\" : missing mendatory key : \"%s\"" section key
  | TooMuchValueForTag { tag } ->
      sprintf "Too Much Value For Tag : \"%s\"" tag
  | MissingAttributes { attribut } ->
      sprintf "Missing attribut : \"%s\"" attribut
  | WrongExpectedTag s ->
      sprintf "Wrong expected tag : \"%s\"" s

let string_of_error = function
  | YomuNotInitialized ->
      Printf.sprintf
        "\"yomu\" directory doesn't exist. Use oyomu init to initialize"
  | YomuCreateConfigError ->
    Printf.sprintf "Unable to create/read the file : %s"
    @@ App.yomu_config_file
  | NoOptionChoosen ->
      "Operation Aborted"
  | MissingInitFile file ->
      Printf.sprintf "The file \"%s\" is missing" file
  | NoFileToDecrypt ->
      Printf.sprintf "No File to decrypt"
  | VolumeAlreadyExisting { comic; volume } ->
      Printf.sprintf "Comic \"%s\": the volume %u already exists" comic volume
  | DecryptionError file ->
      Printf.sprintf "decrptytion error : %s" file
  | AlreadyExistingName filename ->
      Printf.sprintf "Filename : \"%s\" is already in hisoka" filename
  | MissingFile { true_name; encrypted_name } ->
      Printf.sprintf "Filename: \"%s\" is missing: This file encrypted: \"%s\""
        encrypted_name true_name
  | InitError init ->
      string_of_init_error init
  | RenameError ri ->
      string_of_rename_error ri
  | EpubError e ->
      string_of_epub_error e
  | NonExistingGroup groups ->
      let s, does =
        match groups with [] | _ :: [] -> ("", "doesn't") | _ -> ("s", "don't")
      in
      Printf.sprintf "The following group%s %s exist: [%s]" s does
        (String.concat ", " groups)

exception YomuError of error

let yomu_error e = YomuError e
let epub_error e = raise @@ yomu_error @@ EpubError e

let register_exn () =
  Printexc.register_printer (function
    | YomuError error ->
        error |> string_of_error |> Option.some
    | _ ->
        None
    )

let emit_warning s = ignore s
let register_exn = register_exn ()
