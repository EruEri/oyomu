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

let pixels_modes =
  let open Cbindings.Chafa in
  [
    ("symbols", CHAFA_PIXEL_MODE_SYMBOLS);
    ("sixels", CHAFA_PIXEL_MODE_SIXELS);
    ("kitty", CHAFA_PIXEL_MODE_KITTY);
    ("iterm", CHAFA_PIXEL_MODE_ITERM2);
  ]

type t = {
  encrypted : bool;
  pixel_mode : Cbindings.Chafa.pixel_mode;
  all : string list;
  specifics : (int * string) list;
}

let pixel_term =
  Arg.(
    value
    & opt (enum pixels_modes) CHAFA_PIXEL_MODE_SYMBOLS
    & info [ "pixel"; "p" ] ~docv:"PIXEL_MODE"
        ~doc:
          ("pixel mode to use to render the images. "
          ^ doc_alts_enum ~quoted:true pixels_modes
          )
  )

let encrypted_term =
  Arg.(
    value & flag
    & info [ "e"; "encrypt" ] ~doc:"Look also in the encrypted comics"
  )

let all_term =
  Arg.(
    value
    & opt (list string) []
    & info [ "a"; "all" ] ~docv:"COMIC"
        ~doc:
          "A separated list of all the comic where all the volumes should be \
           selected"
  )

let specifics =
  Arg.(
    value
    & pos_all (t2 ~sep:'.' int string) []
    & info [] ~docv:"<VOL.COMIC>" ~doc:"Select for each comic its volume"
  )

let cmd_term run =
  let combine encrypted pixel_mode all specifics =
    run @@ { encrypted; pixel_mode; all; specifics }
  in
  Term.(const combine $ encrypted_term $ pixel_term $ all_term $ specifics)

let doc = "Read comics from collection"
let man = [ `S Manpage.s_description; `P "Read comics from the collection" ] @ Cmdcommon.read_common_description

let cmd run =
  let info = Cmd.info name ~doc ~man in
  Cmd.v info (cmd_term run)

let read_normal all specifics =
  let ( // ) = Libyomu.App.( // ) in
  let archives =
    all
    |> List.filter_map (fun name ->
           let path = Libyomu.App.yomu_comics // name in
           match Sys.file_exists path with
           | false ->
               None
           | true ->
               let dir_content = Sys.readdir path in
               let ldir_content = Array.to_list dir_content in
               let ldir_content = List.sort String.compare ldir_content in
               let archive_paths =
                 ldir_content
                 |> List.map
                    @@ fun file ->
                    let archive_path = path // file in
                    let name = Printf.sprintf "%s-%s" name file in
                    Libyomu.Comic.{ archive_path; name }
               in
               Some archive_paths
       )
  in

  let archives_spe =
    specifics
    |> List.filter_map (fun (index, name) ->
           let path = Libyomu.App.yomu_comics // name in
           match Sys.file_exists path with
           | false ->
               None
           | true ->
               let dir_content = Sys.readdir path in
               let ldir_content = Array.to_list dir_content in
               let ldir_content = List.sort String.compare ldir_content in
               let content =
                 ldir_content
                 |> List.filter_map (fun file ->
                        match
                          int_of_string_opt @@ Filename.remove_extension file
                        with
                        | Some n when n = index ->
                            let name = Printf.sprintf "%s-%s" name file in
                            let archive_path = path // file in
                            let ar = Libyomu.Comic.{ archive_path; name } in
                            Option.some ar
                        | None | Some _ ->
                            None
                    )
               in
               Some content
       )
  in

  archives @ archives_spe |> List.flatten

let read_encrypted ~key all specifics =
  let syomurc = Libyomu.Comic.Syomu.decrypt ~key () in
  let filtered = Libyomu.Comic.Syomu.filter_series all syomurc in
  let fspecifis = Libyomu.Comic.Syomu.filter_vseries specifics syomurc in
  let syomurc = Libyomu.Comic.Syomu.union filtered fspecifis in
  let earchives = Libyomu.Comic.Syomu.decrypt_all ~key syomurc in
  let narchives = read_normal all specifics in
  narchives @ earchives

let run cmd =
  let { encrypted; all; specifics; pixel_mode } = cmd in
  let () = Cmdcommon.check_yomu_initialiaze () in
  let key_opt =
    match encrypted with
    | false ->
        None
    | true ->
        let () = Cmdcommon.check_yomu_hidden () in
        let key =
          Option.some
          @@ Libyomu.Input.ask_password_encrypted
               ~prompt:"Enter the master password : " ()
        in
        key
  in
  let specifics =
    specifics |> List.filter (fun (_, serie) -> not @@ List.mem serie all)
  in
  let archives =
    match key_opt with
    | Some key ->
        let ars = read_encrypted ~key all specifics in
        let () = Gc.compact () in
        ars
    | None ->
        read_normal all specifics
  in
  let () = Libyomu.Drawing.read_comics pixel_mode archives () in
  ()

let command = cmd run
