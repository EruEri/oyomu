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

let name = "list"

type t = { encrypted : bool; comic_only : bool; series : string list }

let encrypted_term =
  Arg.(
    value & flag & info [ "e"; "encrypt" ] ~doc:"List also the encrypted series"
  )

let comic_only_term =
  Arg.(
    value & flag
    & info [ "N"; "name-only" ] ~doc:"Only display the serie's name"
  )

let series_term =
  Arg.(
    value & pos_all string []
    & info [] ~docv:"SERIE"
        ~doc:
          "Only display the given series. If no $(b,docv) is given all series \
           in oyomu are listed"
  )

let cmd_term run =
  let combine encrypted comic_only series =
    run @@ { encrypted; comic_only; series }
  in
  Term.(const combine $ encrypted_term $ comic_only_term $ series_term)

let doc = "List series in collection"
let man = [ `S Manpage.s_description; `P "List series in collection" ]

let cmd run =
  let info = Cmd.info name ~doc ~man in
  Cmd.v info @@ cmd_term run

let normal_entries ~comic_only series =
  let volumes path =
    match comic_only with
    | true ->
        []
    | false ->
        List.sort String.compare @@ Array.to_list @@ Sys.readdir path
  in
  let ( // ) = Filename.concat in
  let always = series = [] in
  Libyomu.App.yomu_comics |> Sys.readdir
  |> Array.fold_left
       (fun acc entry ->
         let path = Libyomu.App.yomu_comics // entry in
         match Sys.is_directory path with
         | false ->
             acc
         | true when always ->
             let comics_volumes = volumes path in
             (entry, comics_volumes) :: acc
         | true -> (
             match List.mem entry series with
             | true ->
                 let comics_volumes = volumes path in
                 (entry, comics_volumes) :: acc
             | false ->
                 acc
           )
       )
       []

let encrypted_entry ~key ~comic_only series =
  let syomurc = Libyomu.Comic.Syomu.decrypt ~key () in
  let eentries = Libyomu.Comic.Syomu.entries syomurc in
  let nentryes = normal_entries ~comic_only series in
  (nentryes, eentries)

let run cmd_list =
  let { encrypted; comic_only; series } = cmd_list in
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
               ~prompt:Cmdcommon.password_prompt ()
        in
        key
  in
  let nentries, eentries =
    match key_opt with
    | Some key ->
        encrypted_entry ~key ~comic_only series
    | None ->
        (normal_entries ~comic_only series, [])
  in
  let () = Libyomu.Collection.list nentries in
  let () =
    match eentries with
    | _ :: _ as eentries ->
        let () = Printf.printf "\n========== Encrypted ==========\n\n" in
        let () = Libyomu.Collection.list eentries in
        ()
    | [] ->
        ()
  in
  ()

let command = cmd run
