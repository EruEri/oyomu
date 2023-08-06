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

module StringSet = Set.Make (struct
  type t = String.t

  let compare lhs rhs =
    let ( <=> ) = String.compare in
    Filename.remove_extension lhs <=> Filename.remove_extension rhs
end)

module SItemSet = Set.Make (struct
  type t = Libyomu.Comic.syomu_item

  let compare (lhs : t) (rhs : t) = compare lhs.volume rhs.volume
end)

let name = "rename"

type t = {
  encrypted : bool;
  merge : bool;
  old_name : string;
  new_name : string;
}

let merge_term =
  Arg.(
    value & flag
    & info [ "m"; "merge" ]
        ~doc:
          "If the new comic name points to an existing serie, try to merge all \
           the comics into that serie"
  )

let encrypted_term =
  Arg.(
    value & flag
    & info [ "e"; "encrypt" ] ~doc:"Look also in the encrypted comics"
  )

let old_name_term =
  Arg.(
    required
    & pos 0 (some string) None
    & info [] ~docv:"<OLDNAME>" ~doc:"Name of the comic that should be renamed"
  )

let new_name_term =
  Arg.(
    required
    & pos 1 (some string) None
    & info [] ~docv:"<NEWNAME>"
        ~doc:"Name of the comic that replace the old one"
  )

let cmd_term run =
  let combine encrypted merge old_name new_name =
    run @@ { encrypted; merge; old_name; new_name }
  in
  Term.(
    const combine $ encrypted_term $ merge_term $ old_name_term $ new_name_term
  )

let doc = "Rename comics"
let man = [ `S Manpage.s_description; `P doc ]

let merge_yomu ~old_name ~new_name ~oldyomu ~targetyomu syomurc =
  let open Libyomu.Comic in
  let old_content = SItemSet.of_list oldyomu.scomics in
  let new_content = SItemSet.of_list targetyomu.scomics in
  let conflicting_set = SItemSet.inter old_content new_content in
  let scomics =
    match SItemSet.is_empty conflicting_set with
    | false ->
        let conflits =
          conflicting_set |> SItemSet.elements
          |> List.map (fun { serie; volume; _ } ->
                 Printf.sprintf "%s Vol-%u" serie volume
             )
        in
        raise
        @@ Libyomu.Error.(
             yomu_error
             @@ Rename_Error
                  (Complicting_volume
                     { oldname = old_name; newname = new_name; conflits }
                  )
           )
    | true ->
        Libyomu.Comic.Syomu.rename_serie old_name new_name syomurc
  in
  scomics

let rename_encrypted merge ~key ~old_name ~new_name =
  let syomurc = Libyomu.Comic.Syomu.decrypt ~key () in
  let old_series_syomu =
    Libyomu.Comic.Syomu.filter_series [ old_name ] syomurc
  in
  let () =
    match old_series_syomu.scomics with
    | [] ->
        raise
        @@ Libyomu.Error.(yomu_error @@ Rename_Error (Comic_not_exist old_name))
    | _ :: _ ->
        ()
  in
  let new_series_syomu =
    Libyomu.Comic.Syomu.filter_series [ new_name ] syomurc
  in
  let new_syomu =
    match new_series_syomu.scomics with
    | [] ->
        Libyomu.Comic.Syomu.rename_serie old_name new_name syomurc
    | _ :: _ when not merge ->
        raise
        @@ Libyomu.Error.(
             yomu_error @@ Rename_Error (Comic_already_exist new_name)
           )
    | _ :: _ ->
        merge_yomu ~old_name ~new_name ~oldyomu:old_series_syomu
          ~targetyomu:new_series_syomu syomurc
  in
  let _ = Libyomu.Comic.Syomu.encrypt ~key new_syomu () in
  ()

let rename_normal merge ~old_name ~new_name =
  let ( // ) = Libyomu.App.( // ) in
  let old_path = Libyomu.App.yomu_share // old_name in
  let new_path = Libyomu.App.yomu_share // new_name in
  let exist_old = Sys.file_exists old_path && Sys.is_directory old_path in
  let exist_new = Sys.file_exists new_path && Sys.is_directory new_path in
  match (exist_old, exist_new) with
  | true, false ->
      Sys.rename old_path new_path
  | false, (true | false) ->
      raise
      @@ Libyomu.Error.(yomu_error @@ Rename_Error (Comic_not_exist old_name))
  | true, true -> (
      match merge with
      | false ->
          raise
          @@ Libyomu.Error.(
               yomu_error @@ Rename_Error (Comic_already_exist new_name)
             )
      | true ->
          let old_content =
            old_path |> Sys.readdir |> Array.to_seq |> StringSet.of_seq
          in
          let new_content =
            new_path |> Sys.readdir |> Array.to_seq |> StringSet.of_seq
          in
          let conflicting_set = StringSet.inter old_content new_content in
          let () =
            match StringSet.is_empty conflicting_set with
            | false ->
                let conflits = StringSet.elements conflicting_set in
                raise
                @@ Libyomu.Error.(
                     yomu_error
                     @@ Rename_Error
                          (Complicting_volume
                             {
                               oldname = old_name;
                               newname = new_name;
                               conflits;
                             }
                          )
                   )
            | true ->
                StringSet.iter
                  (fun elt ->
                    let oldpath_comic = old_path // elt in
                    let newpath_comic = new_path // elt in
                    Sys.rename oldpath_comic newpath_comic
                  )
                  old_content
          in
          ()
    )

let cmd run =
  let info = Cmd.info name ~doc ~man in
  Cmd.v info (cmd_term run)

let run cmd =
  let { encrypted; merge; old_name; new_name } = cmd in
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
  let () =
    match key_opt with
    | None ->
        rename_normal merge ~old_name ~new_name
    | Some key ->
        rename_encrypted merge ~key ~old_name ~new_name
  in
  ()

let command = cmd run
