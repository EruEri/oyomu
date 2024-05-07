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

  let name = "oyomu"
  let version = Libyomu.Config.version
  let root_doc = "a comic reader"

  let root_man =
    [
      `S Manpage.s_description;
      `P "$(iname) allows to manage and read your comic collection";
    ]

  let root_info = Cmd.info name ~doc:root_doc ~man:root_man ~version
  let subcommands = [ Read.command; Cmdcollection.command; Config.command ]
  let commands = Cmd.group root_info subcommands
  let eval () = Cmd.eval commands
end
