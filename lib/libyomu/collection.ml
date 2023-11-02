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

let check_exist path () =
  match Sys.file_exists path with
  | true ->
      ()
  | false ->
      failwith @@ "File doesnt exist" ^ path

let space level = String.init level (fun _ -> ' ')

(** [volumes comic] returns the path of the [comic] and its content *)
let volumes comic =
  let open App in
  let path = yomu_comics // comic in
  match Sys.file_exists path with
  | true ->
      (path, Some (Sys.readdir path))
  | false ->
      (path, None)

let convert_name index archive =
  let extension = Filename.extension archive in
  Printf.sprintf "%u%s" index extension

let are_same_volume lhs rhs =
  let lhs = Filename.basename lhs in
  let rhs = Filename.basename rhs in
  rhs = lhs

module Normal = struct
  let add ~comic_name ~comic_dir ~comic_dir_content index comic_archive =
    let open App in
    let indexed_archive = convert_name index comic_archive in
    let path = comic_dir // indexed_archive in
    let () =
      match
        Array.exists (are_same_volume indexed_archive) comic_dir_content
      with
      | false ->
          Util.Io.cp comic_archive path
      | true ->
          raise
          @@ Error.(
               yomu_error
               @@ Volume_already_existing { comic = comic_name; volume = index }
             )
    in
    ()

  let add_multiples ~comic_name ~comic_dir ~comic_dir_content files =
    let () =
      List.iter
        (fun (index, archive) ->
          add ~comic_name ~comic_dir ~comic_dir_content index archive
        )
        files
    in
    ()
end

module Encrypted = struct
  let check_serie_exist comic_name syomurc () =
    match Syomu.serie_exists comic_name syomurc with
    | true ->
        ()
    | false ->
        failwith "S: Serie doesnt exist"

  let check_duplicate comic_name volume syomurc () =
    match Syomu.exists volume comic_name syomurc with
    | false ->
        ()
    | true ->
        failwith "S: Duplicated exist"

  let dname comic_name index comic_archive =
    let extension = Filename.extension comic_archive in
    let s = Printf.sprintf "%s_%u_%s" comic_name index comic_archive in
    (s, extension)

  (*  *)

  let add_encrypted ~key ~existing ~comic_name index comic_archive syomurc =
    let ( // ) = App.( // ) in
    let () =
      match existing with
      | true ->
          check_serie_exist comic_name syomurc ()
      | false ->
          ()
    in
    let () =
      match existing with
      | true ->
          check_serie_exist comic_name syomurc ()
      | false ->
          ()
    in
    let () = check_duplicate comic_name index syomurc () in
    let name, extension = dname comic_name index comic_archive in
    let digest_name = Util.Hash.hash_name ~name ~extension in
    let item = Syomu.create_item digest_name comic_name index in
    let content = Util.Io.content_filename comic_archive () in
    let content_outfile = App.yomu_hidden_comics // digest_name in
    let _encrypted_content =
      Encryption.encrypt ~where:content_outfile ~key ~iv:item.iv content ()
    in
    let syomurc = Syomu.add item syomurc in
    syomurc

  let add_multiples ~key ~existing ~comic_name indexed_archives =
    let syomurc = Syomu.decrypt ~key () in
    let syomurc =
      indexed_archives
      |> List.fold_left
           (fun syomurc (index, archive) ->
             add_encrypted ~key ~comic_name ~existing index archive syomurc
           )
           syomurc
    in
    let _ = Syomu.encrypt ~key syomurc () in
    ()
end

let clear_tmp_files () =
  let temp_folder = Filename.get_temp_dir_name () in
  temp_folder |> Sys.readdir
  |> Array.iter (fun file ->
         let file = Filename.concat temp_folder file in
         match file with
         | file
           when (try not @@ Sys.is_directory file with _ -> false)
                && String.ends_with ~suffix:"yomu" file ->
             Util.FileSys.rmrf file ()
         | _ ->
             ()
     )

type entry = string * string list

let list entries =
  entries
  |> List.iter (fun (name, volumes) ->
         Printf.printf "─ %s:\n\t%s\n%!"
           (Util.AsciiString.bold name)
           (volumes |> List.map (Printf.sprintf "- %s") |> String.concat "\n\t")
     )
