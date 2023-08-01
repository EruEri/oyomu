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

let name = "delete"

type t = {
  encrypted : bool;
  all : string list;
  specifics : (int * string) list;
}

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
    & info [] ~docv:"<VOL.COMIC>"
        ~doc:"Select for each comic its volume to delete"
  )

let cmd_term run =
  let combine encrypted all specifics = run @@ { encrypted; all; specifics } in
  Term.(const combine $ encrypted_term $ all_term $ specifics)

let doc = "Delete comics from collection"

let man_example =
  [
    `S Manpage.s_examples;
    `I
      ( "To delete all volume from the series $(b,ComicA) and $(b,ComicB)",
        "$(iname) --all ComicA, ComicB"
      );
    `I
      ( "To delete the first volume from the serie $(b,ComicB)",
        "$(iname) 1.ComicB"
      );
    `P
      "To delete comics which are encrypted, you should also provide the \
       $(b,e) flag";
    `I
      ( "To delete the third volume of the encrypted serie $(b,ComicE)",
        "$(iname) -e 3.ComicE"
      );
  ]

let man = [ `S Manpage.s_description; `P doc ] @ man_example

let cmd run =
  let info = Cmd.info name ~doc ~man in
  Cmd.v info (cmd_term run)

(** Return *)
let rmrf_safe ?message path =
  match Util.FileSys.rmrf path () with
  | () ->
      Ok ()
  | exception _ ->
      let () = Option.iter print_string message in
      Error ()

let delete_normal all specifics =
  let ( // ) = Libyomu.App.( // ) in
  let () =
    all
    |> List.iter
       @@ fun serie ->
       let path = Libyomu.App.yomu_comics // serie in
       let error_message = Printf.sprintf "No serie : %s\n%!" serie in
       let _ = rmrf_safe ~message:error_message path in
       ()
  in
  let fn_serie_to_check_folder (index, serie) =
    let path = Libyomu.App.yomu_comics // serie in
    match Sys.file_exists path with
    | false ->
        None
    | true ->
        let dir_content = Sys.readdir path in
        let ldir_content = Array.to_list dir_content in
        let _ =
          ldir_content
          |> List.map (fun file ->
                 match int_of_string_opt @@ Filename.remove_extension file with
                 | Some n when n = index ->
                     let comic_path = path // file in
                     let error_message =
                       Printf.sprintf "No file: %s\n%!" comic_path
                     in
                     Result.is_ok @@ rmrf_safe ~message:error_message comic_path
                 | None | Some _ ->
                     false
             )
        in
        (* let () =
             match List.exists Fun.id content with
             | false ->
                 ()
             | true ->
                 failwith ""
           in *)
        Some serie
  in

  let () =
    specifics
    |> List.filter_map fn_serie_to_check_folder
    |> List.iter (fun serie ->
           let folder_path = Libyomu.App.yomu_comics // serie in
           let folder_content = Sys.readdir folder_path in
           match Array.length folder_content with
           | 0 ->
               ignore @@ rmrf_safe folder_path
           | _ ->
               ()
       )
  in
  ()

let delete_encrypted ~key all specifics =
  let ( // ) = Libyomu.App.( // ) in
  let syomurc = Libyomu.Comic.Syomu.decrypt ~key () in
  let syomurc, exludes = Libyomu.Comic.Syomu.exclude_series all syomurc in

  let syomurc, f_exclu =
    Libyomu.Comic.Syomu.excludes_vseries specifics syomurc
  in
  let delete_files list =
    list
    |> List.iter
       @@ fun sitem ->
       let path =
         Libyomu.App.yomu_hidden_comics
         // sitem.Libyomu.Comic.encrypted_file_name
       in
       let message = Printf.sprintf "Cannot delete file: %s\n%!" path in
       let _ = rmrf_safe ~message path in
       ()
  in
  let () = delete_files exludes in
  let () = delete_files f_exclu in
  let () = ignore @@ Libyomu.Comic.Syomu.encrypt ~key syomurc () in
  ()

let run cmd =
  let { encrypted; all; specifics } = cmd in
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
  let specifics =
    specifics |> List.filter (fun (_, serie) -> not @@ List.mem serie all)
  in
  let () =
    match key_opt with
    | Some key ->
        delete_encrypted ~key all specifics
    | None ->
        delete_normal all specifics
  in
  ()

let command = cmd run
