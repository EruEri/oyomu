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

let name = "add"

type t = {
  encrypted : bool;
  comic : string;
  existing : bool;
  files : string list;
  start_index : int;
}

let comic_term =
  Arg.(
    required
    & opt (some string) None
    & info [ "n"; "name" ] ~docv:"COMIC_NAME" ~doc:"Name of the comic"
  )

let encrypted_term = Arg.(value & flag & info [ "e"; "encrypt" ])

let existing_term =
  Arg.(
    value & flag
    & info [ "x"; "exist" ] ~doc:"Indicate that the comic should already exist"
  )

let cover_term =
  Arg.(value & opt (some file) None & info [ "c"; "cover" ] ~doc:"")

let start_index_term =
  let s1 = Some 1 in
  Arg.(
    required
    & opt ~vopt:s1 (some int) s1
    & info [ "i"; "index" ] ~docv:"START_INDEX" ~doc:"Volume starting index"
  )

let files_term =
  let linfo =
    Arg.info [] ~docv:"<FILES.(cbz|zip)>"
      ~doc:"Archive of the comic. The archives must be zip archive"
  in
  Arg.(non_empty & pos_all non_dir_file [] & linfo)

let cmd_term run =
  let combine encrypted comic existing start_index files =
    run @@ { encrypted; comic; existing; start_index; files }
  in
  Term.(
    const combine $ encrypted_term $ comic_term $ existing_term
    $ start_index_term $ files_term
  )

let cmd_doc = "Add comics to the collection"
let cmd_man = [ `S Manpage.s_description; `P "Add comics to the collection" ]

let cmd run =
  let info = Cmd.info name ~doc:cmd_doc ~man:cmd_man in
  Cmd.v info (cmd_term run)

let add_normal ~existing ~comic_name indexed_archives =
  let path, content = Libyomu.Collection.volumes comic_name in
  let comic_dir_content =
    match content with
    | Some c ->
        c
    | None when existing ->
        failwith @@ "No manga " ^ comic_name ^ "Exist"
    | None ->
        let () =
          match
            Util.FileSys.create_folder
              ~on_error:(Libyomu.Error.Create_folder path) path
          with
          | Ok _ ->
              ()
          | Error e ->
              raise @@ Libyomu.Error.(yomu_error @@ Init_Error e)
        in
        Array.init 0 (fun _ -> String.empty)
  in
  Libyomu.Collection.Normal.add_multiples ~comic_name ~comic_dir:path
    ~comic_dir_content indexed_archives

let run cmd_read =
  let { encrypted; comic; existing; start_index; files } = cmd_read in
  let () = ignore (comic, existing, start_index, files) in
  let () =
    match start_index with
    | n when n < 0 ->
        failwith "negative volume"
    | _ ->
        ()
  in

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

  let files = List.mapi (fun i file -> (i + start_index, file)) files in

  let () =
    match key_opt with
    | None ->
        add_normal ~comic_name:comic ~existing files
    | Some key ->
        Libyomu.Collection.Encrypted.add_multiples ~key ~existing
          ~comic_name:comic files
  in
  let () = Printf.printf "Successfully added:\n%!" in
  let () =
    files
    |> List.iter (fun (index, name) ->
           Printf.printf "    Vol.%u : %s\n" index (Filename.basename name)
       )
  in
  ()

let command = cmd run
