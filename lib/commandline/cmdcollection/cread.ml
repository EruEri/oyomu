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
  encrypted : bool;
  keep_unzipped : bool option;
  regex : bool;
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

let regex_term =
  Arg.(value & flag & info [ "r" ] ~doc:"Treat comic name as a regex")

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
  let combine encrypted keep_unzipped regex pixel_mode all specifics =
    run @@ { encrypted; keep_unzipped; regex; pixel_mode; all; specifics }
  in
  Term.(
    const combine $ encrypted_term $ Cmdcommon.keep_unzipped_term $ regex_term
    $ pixel_term $ all_term $ specifics
  )

let man_example =
  [
    `S Manpage.s_examples;
    `I
      ( "To read all volume from the series $(b,ComicA) and $(b,ComicB)",
        "$(iname) --all ComicA, ComicB"
      );
    `I
      ( "To read the first volume from the serie $(b,ComicB)",
        "$(iname) 1.ComicB"
      );
    `I ("To read the first volume of all series", "$(iname) -r 1..");
    `P
      "To read comics which are encrypted, you should also provide the $(b,-e) \
       flag";
    `I
      ( "To read the third volume of the encrypted serie $(b,ComicE)",
        "$(iname) -e 3.ComicE"
      );
  ]

let doc = "Read comics from collection"

let man =
  [ `S Manpage.s_description; `P "Read comics from the collection" ]
  @ man_example @ Cmdcommon.read_common_description

let cmd run =
  let info = Cmd.info name ~doc ~man in
  Cmd.v info (cmd_term run)

let read_normal regex all specifics =
  let archives = List.map (Libyomu.Collection.Normal.matchesp regex) all in

  let archives_spe =
    List.map
      (fun (index, name) -> Libyomu.Collection.Normal.matchesip regex index name)
      specifics
  in

  List.flatten @@ archives @ archives_spe

let read_encrypted ~key regex all specifics =
  let syomurc = Libyomu.Syomu.decrypt ~key () in
  let filtered = Libyomu.Syomu.filter_series regex all syomurc in
  let fspecifis = Libyomu.Syomu.filter_vseries regex specifics syomurc in
  let syomurc = Libyomu.Syomu.union filtered fspecifis in
  let earchives = Libyomu.Syomu.decrypt_all ~key syomurc in
  let narchives = read_normal regex all specifics in
  narchives @ earchives

let run cmd =
  let { encrypted; keep_unzipped; regex; all; specifics; pixel_mode } = cmd in
  let (config, _lines_errors), _err =
    match Libyomu.Keys.parse ?keep_unzipped () with
    | Ok c ->
        (c, false)
    | Error _ ->
        ((Libyomu.Keys.empty, []), true)
  in
  let () = Cmdcommon.check_yomu_initialiaze () in
  let key_opt = Cmdcommon.ask_password_if_encrypted encrypted () in
  let specifics =
    specifics |> List.filter (fun (_, serie) -> not @@ List.mem serie all)
  in
  let archives =
    match key_opt with
    | Some key ->
        let ars = read_encrypted ~key regex all specifics in
        let () = Gc.compact () in
        ars
    | None ->
        read_normal regex all specifics
  in
  let () = Libyomu.Drawing.read_comics ~config pixel_mode archives () in
  ()

let command = cmd run
