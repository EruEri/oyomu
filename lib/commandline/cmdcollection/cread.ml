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
          ("pixel mode to use to render the images"
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
let man = [ `S Manpage.s_description; `P "Read comics from the collection" ]

let cmd run =
  let info = Cmd.info name ~doc ~man in
  Cmd.v info (cmd_term run)

let read_normal all specifics =
  let ( // ) = Libyomu.App.( // ) in
  let archives =
    all
    |> List.map (fun name ->
           let path = Libyomu.App.yomu_comics // name in
           match Sys.file_exists path with
           | false ->
               failwith "TODO: comics doesnt exist"
           | true ->
               let dir_content = Sys.readdir path in
               let ldir_content = Array.to_list dir_content in
               let content = ldir_content |> List.map @@ ( // ) path in
               content
       )
  in

  let archives_spe =
    specifics
    |> List.map (fun (index, name) ->
           let path = Libyomu.App.yomu_comics // name in
           match Sys.file_exists path with
           | false ->
               failwith "TODO: comics doesnt exist"
           | true ->
               let dir_content = Sys.readdir path in
               let ldir_content = Array.to_list dir_content in
               let content =
                 ldir_content
                 |> List.filter_map (fun file ->
                        match
                          int_of_string_opt @@ Filename.remove_extension file
                        with
                        | Some n when n = index ->
                            Option.some @@ (path // file)
                        | None | Some _ ->
                            None
                    )
               in
               content
       )
  in
  archives @ archives_spe |> List.flatten

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
    | Some _ ->
        failwith "TODO: Encryped read"
    | None ->
        read_normal all specifics
  in
  let () = Libyomu.Drawing.read_comics pixel_mode archives () in
  ()

let command = cmd run
