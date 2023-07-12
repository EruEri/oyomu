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

type t = {
  force: bool
}

let name = "init"

let force_term =
  let finfo = Arg.info [ "f"; "force" ] ~doc:"force the initialisation" in
  Arg.(value & flag & finfo)

let cmd_term run =
  let combine force = run @@ { force } in
  Term.(const combine $ force_term)


let cmd_doc = "Initialise yomu"
let cmd_man = [ `S Manpage.s_description; `P "Initialise yomu" ]

let cmd run =
  let info = Cmd.info name ~doc:cmd_doc ~man:cmd_man in
  Cmd.v info (cmd_term run)

let run cmd_init =
  let open Util.FileSys in
  let force = cmd_init.force in
  (* let ( >>= ) = Result.bind in *)
  let is_app_folder_exist = Sys.file_exists App.share_yomu in
  let res =
    if is_app_folder_exist && not force then
      Error Error.(App_folder_already_exist App.share_yomu)
    else
      let () =
        if is_app_folder_exist && force then
          rmrf App.share_yomu ()
      in
      (* let first_message = "Choose the master password : " in
      let confirm_message = "Confirm the master password : " in
      let encrypted_key =
        match
          Input.confirm_password_encrypted ~first_message ~confirm_message ()
        with
        | Ok encrypted_key ->
            encrypted_key
        | Error exn ->
            raise (Input.PassError exn)
      in *)
      create_folder ~on_error:(Error.Create_folder App.share_yomu) App.share_yomu
      (* >>= fun app_dir ->
      let external_file_path = PathBuf.push hisoka_rc app_dir in
      let external_manager = Manager.External_Manager.create in
      let data =
        Manager.External_Manager.encrypt ~key:encrypted_key external_manager
          ()
      in
      create_file
        ~on_file:(fun oc -> output_string oc data)
        ~on_error:(Error.Create_file external_file_path) external_file_path
      >>= fun external_file_path ->
      let app_dir = PathBuf.pop external_file_path in
      let data_foler_dir = PathBuf.push data_folder app_dir in
      create_folder ~on_error:(Error.Create_folder data_foler_dir)
        data_foler_dir *)
  in
  match res with
  | Ok _ ->
      Printf.printf "Yomu initialized\n"
  | Error init_error ->
      raise (Error.YomuError (Init_Error init_error))

let command = cmd run

