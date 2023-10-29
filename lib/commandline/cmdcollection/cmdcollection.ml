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

let name = "collection"
let doc = "Manage Oyomu collection"

type t = { randomize_iv : bool }

let term_random_iv =
  Arg.(
    value & flag
    & info ~doc:"Randomize the initialization vector of the encrypted comics"
        [ "randomize-iv" ]
  )

let term_cmd run =
  let combine randomize_iv = run { randomize_iv } in
  Term.(const combine $ term_random_iv)

let run t =
  let { randomize_iv } = t in
  let () =
    match randomize_iv with
    | false ->
        ()
    | true ->
        let () = Cmdcommon.check_yomu_hidden () in
        let key =
          Libyomu.Input.ask_password_encrypted ~prompt:Cmdcommon.password_prompt
            ()
        in
        let syomurc = Libyomu.Comic.Syomu.decrypt ~key () in
        let syomurc = Libyomu.Comic.Syomu.randomize_iv syomurc in
        let _ = Libyomu.Comic.Syomu.encrypt ~key syomurc () in
        ()
  in
  ()

let man =
  [
    `S Manpage.s_description;
    `P "$(iname) allows you to manager and read your comic collection";
  ]

let root_info = Cmd.info name ~doc ~man

let subcommands =
  [
    Cadd.command;
    Cread.command;
    Clist.command;
    Cdelete.command;
    Cinit.command;
    Cdecrypt.command;
    Crename.command;
  ]

let parse () = Cmd.group ~default:(term_cmd run) root_info subcommands
let command = parse ()
