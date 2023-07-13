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

let name = "read"

let pixels_modes = let open Cbindings.Chafa in [
  ("symbols", CHAFA_PIXEL_MODE_SYMBOLS);
  ("sixels", CHAFA_PIXEL_MODE_SIXELS);
  ("kitty", CHAFA_PIXEL_MODE_KITTY);
  ("iterm", CHAFA_PIXEL_MODE_ITERM2);
  ("max", CHAFA_PIXEL_MODE_MAX);
]

type t = {
  mode: Cbindings.Chafa.pixel_mode;
  files: string list
}

let file_term =
  let linfo = Arg.info [] ~docv:"<FILES.(cbz|zip)>" ~doc:"Archive of the comic. The archives must be zip archive" in
  Arg.(non_empty & pos_all non_dir_file [] & linfo)

let pixel_term = 
  Arg.(
    value 
    & opt (enum pixels_modes) CHAFA_PIXEL_MODE_SYMBOLS 
    & info ["pixel"; "p"]
    ~docv:"PIXEL_MODE"
    ~doc:"pixel mode to use to render the images"
  )

let cmd_term run =
  let combine files mode =
    run @@ { files; mode }
  in
  Term.(
    const combine
    $ file_term
    $ pixel_term

  )


let cmd_doc = "Read comics"

let cmd_man = 
  [
    `S Manpage.s_description;
    `P "Read commic"; 
  ]

let cmd run =
  let info = Cmd.info name ~doc:cmd_doc ~man:cmd_man in
  Cmd.v info (cmd_term run)

let run cmd_read =
  let { files; mode } = cmd_read in
  (* ignore files;
  ignore mode;
  let file = List.hd files in
  let comic = Libyomu.Comic.comic_of_zip file in
  let _ = comic in *)
  (* let () = Cbindings.Display.comic_read Iterm files () in *)
  let () = Libyomu.Drawing.read_comics mode files () in
  ()

let command = cmd run