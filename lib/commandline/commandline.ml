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

module Main = struct
  open Cmdliner

  let name = "yomu"
  let version =
    match Build_info.V1.version () with
    | None ->
        "n/a"
    | Some v ->
        Build_info.V1.Version.to_string v

  let root_doc = "a comic reader"

  let root_man =
    [
      `S Manpage.s_description;
      `P "$(iname) allows to manager and read your comic collection";
    ]

  let root_info = Cmd.info name ~doc:root_doc ~man:root_man ~version

  let subcommands =
    [
      Init.command;
      Read.command
    ]

  let parse () = Cmd.group root_info subcommands
  let eval () = 
    let () = Libyomu.Ccallback.register_callback () in
    () |> parse |> Cmd.eval
end