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

open Cmdliner
open Libyomu

type t = { encrypted : bool; force : bool }

let name = "init"

let encrypt_term =
  Arg.(
    value & flag
    & info [ "e"; "encryption" ] ~doc:"Init the encrypted part of oyomu"
  )

let force_term =
  let finfo = Arg.info [ "f"; "force" ] ~doc:"force the initialisation" in
  Arg.(value & flag & finfo)

let cmd_term run =
  let combine encrypted force = run @@ { encrypted; force } in
  Term.(const combine $ encrypt_term $ force_term)

let cmd_doc = "Initialise the comics collection "

let cmd_man =
  [
    `S Manpage.s_description;
    `P "Oyomu allows you to manage your comics collection";
    `Noblank;
    `P "Oyomu's collection has 2 sides";
    `I
      ( "Normal:",
        Printf.sprintf
          "This side stores your comics directly in your $(b, \
           \\%cXDG_DATA_HOME/yomu/comics) directory"
          '$'
      );
    `I
      ( "Encrypted:",
        Printf.sprintf
          "This side stores your comics by encrypting them in your $(b, \
           \\%cXDG_DATA_HOME/yomu/.scomics)."
          '$'
      );
    `P
      "Note that, adding the same comic in $(b,Normal) and $(c,Encrypted) will \
       $(b,not) causeduplicate issue since there treated as 2 separated \
       collections\n\
      \    ";
  ]

let cmd run =
  let info = Cmd.info name ~doc:cmd_doc ~man:cmd_man in
  Cmd.v info (cmd_term run)

let init_encrypted () =
  let first_message = "Choose the master password :" in
  let confirm_message = "Confirm the master password : " in
  let encrypted_key =
    match
      Libyomu.Input.confirm_password_encrypted ~first_message ~confirm_message
        ()
    with
    | Ok encrypted_key ->
        encrypted_key
    | Error exn ->
        raise (Input.PassError exn)
  in
  Libyomu.Init.create_yomu_hidden ~key:encrypted_key ()

let init_normal () =
  let ( >>= ) = Result.bind in
  Libyomu.Init.create_yomu_share ()
  >>= fun _ -> Libyomu.Init.create_yomu_comics ()

let clear_if should_clear () =
  match should_clear with
  | false ->
      ()
  | true ->
      Util.FileSys.rmrf App.yomu_share ()

let run cmd_init =
  let { encrypted; force } = cmd_init in
  let ( >== ) = Result.bind in
  let is_app_folder_exist = Sys.file_exists App.yomu_share in
  let res =
    match is_app_folder_exist && not (force || encrypted) with
    | true ->
        Error Error.(App_folder_already_exist App.yomu_share)
    | false ->
        let () = clear_if (is_app_folder_exist && force) () in
        let res =
          match is_app_folder_exist with
          | true when encrypted ->
              init_encrypted ()
          | false | true -> (
              init_normal ()
              >== fun s ->
              match encrypted with false -> Ok s | true -> init_encrypted ()
            )
        in

        res
  in
  match res with
  | Ok _ ->
      Printf.printf "Yomu initialized\n"
  | Error init_error ->
      raise @@ Error.(yomu_error @@ Init_Error init_error)

let command = cmd run
