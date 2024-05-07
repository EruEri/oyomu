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
      raise @@ Error.(yomu_error @@ FileNotExist path)

let space level = String.init level (Fun.const ' ')

(** [volumes comic] returns the path of the [comic] and its content *)
let volumes comic =
  let open Config in
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
    let open Config in
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
               @@ VolumeAlreadyExisting { comic = comic_name; volume = index }
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

  (**
      [named_archive_of_name root comic_name file_name]  
    *)
  let named_archive_of_name root comic_name file_name =
    let ( // ) = Filename.concat in
    let archive_path = root // comic_name // file_name in
    let name = Printf.sprintf "%s-%s" comic_name file_name in
    Item.{ archive_path; name }

  let yomu_comics () = Array.to_list @@ Sys.readdir Config.yomu_comics

  (**
        [read_comic_dir name] read the content of [Libyomu.Config.yomu_comics/name]
    *)
  let read_comic_dir name =
    let full_path = Filename.concat Config.yomu_comics name in
    List.filter (Fun.negate @@ String.starts_with ~prefix:".")
    @@ Array.to_list @@ Sys.readdir full_path

  (**
      [matchesp regex s] matches the the comics with the name [name] and converts all comics to 
      [Item.named_archive]. If [regex], [name] is treated as a regular expression
  *)
  let matchesp regex s =
    let regexp =
      match regex with true -> Str.regexp s | false -> Str.regexp_string s
    in
    yomu_comics ()
    |> List.filter_map (fun name ->
           match Str.string_match regexp name 0 with
           | true when not @@ String.starts_with ~prefix:"." name ->
               let elts = read_comic_dir name in
               Option.some
               @@ List.sort NamedArchive.compare_named_archive
               @@ List.map (named_archive_of_name Config.yomu_comics name) elts
           | false | true ->
               None
       )
    |> List.flatten

  (**
      [matchesip regex index name] matches the the comics with the name [name] and its index [index] and converts all comics to 
      [Item.named_archive]. If [regex], [name] is treated as a regular expression
  *)
  let matchesip regex index name =
    let regexp =
      match regex with
      | true ->
          Str.regexp name
      | false ->
          Str.regexp_string name
    in
    let ( // ) = Filename.concat in
    yomu_comics ()
    |> List.filter_map (fun name ->
           match Str.string_match regexp name 0 with
           | true when not @@ String.starts_with ~prefix:"." name ->
               Some (name, read_comic_dir name)
           | false | true ->
               None
       )
    |> List.map (fun (comic_name, elts) ->
           let archive_path =
             List.filter_map
               (fun file ->
                 match int_of_string_opt @@ Filename.remove_extension file with
                 | Some n when n = index ->
                     let path = Config.yomu_comics // comic_name in
                     let name = Printf.sprintf "%s-%s" comic_name file in
                     let archive_path = path // file in
                     let ar = Item.{ archive_path; name } in
                     Option.some ar
                 | None | Some _ ->
                     None
               )
               elts
           in
           archive_path
       )
    |> List.flatten
end

module Encrypted = struct
  let check_serie_exist comic_name syomurc () =
    match Syomu.serie_exists comic_name syomurc with
    | true ->
        ()
    | false ->
        raise @@ Error.(yomu_error @@ ComicNotExist comic_name)

  let check_duplicate comic_name volume syomurc () =
    match Syomu.exists volume comic_name syomurc with
    | false ->
        ()
    | true ->
        raise
        @@ Error.(
             yomu_error @@ VolumeAlreadyExisting { comic = comic_name; volume }
           )

  let dname comic_name index comic_archive =
    let extension = Filename.extension comic_archive in
    let s = Printf.sprintf "%s_%u_%s" comic_name index comic_archive in
    (s, extension)

  (*  *)

  let add_encrypted ~key ~existing ~comic_name index comic_archive syomurc =
    let ( // ) = Config.( // ) in
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
    let content_outfile = Config.yomu_hidden_comics // digest_name in
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
