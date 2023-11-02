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
let pixels_modes = Libyomu.Pixel.pixels_modes

type t = {
  mode : Cbindings.Chafa.pixel_mode;
  keep_unzipped : bool option;
  files : string list;
}

let file_term =
  let linfo =
    Arg.info [] ~docv:"<FILES.(cbz|zip)>"
      ~doc:"Archive of the comic. The archives must be zip archive"
  in
  Arg.(non_empty & pos_all non_dir_file [] & linfo)

let pixel_term =
  Arg.(
    value
    & opt (enum pixels_modes) CHAFA_PIXEL_MODE_SYMBOLS
    & info [ "pixel"; "p" ] ~docv:"PIXEL_MODE"
        ~doc:
          ("pixel mode to use to render the images"
          ^ doc_alts_enum ~quoted:true pixels_modes
          )
  )

let cmd_term run =
  let combine mode keep_unzipped files =
    run @@ { mode; keep_unzipped; files }
  in
  Term.(const combine $ pixel_term $ Cmdcommon.keep_unzipped_term $ file_term)

let cmd_doc = "Read comics"

let cmd_man =
  [ `S Manpage.s_description; `P "Read commics" ]
  @ Cmdcommon.read_common_description

let cmd run =
  let info = Cmd.info name ~doc:cmd_doc ~man:cmd_man in
  Cmd.v info (cmd_term run)

let archive_of_file file =
  let archive_path = file in
  let name = Filename.remove_extension @@ Filename.basename @@ file in
  Libyomu.Item.{ archive_path; name }

let run cmd_read =
  let { files; keep_unzipped; mode } = cmd_read in
  let (config, _lines_errors), _err =
    match Libyomu.App.Config.parse ?keep_unzipped () with
    | Ok c ->
        (c, false)
    | Error _ ->
        ((Libyomu.App.Config.empty, []), true)
  in
  let files = List.map archive_of_file files in
  let () = Libyomu.Drawing.read_comics ~config mode files () in
  ()

let command = cmd run
