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

open Item

let encryption_iv = String.init 12 (fun index -> Char.chr ((index + 1) mod 256))

(** [create_item encrypted_file_name serie volume] create a new [syomu_item] with a random iv *)
let create_item encrypted_file_name serie volume =
  { iv = Encryption.random_iv (); encrypted_file_name; serie; volume }

let create = { scomics = [] }
let to_string manager = manager |> syomurc_to_yojson |> Yojson.Safe.to_string
let of_string bytes = bytes |> Yojson.Safe.from_string |> syomurc_of_yojson

let encrypt ~key syomurc () =
  let data = to_string syomurc in
  let where = App.yomu_hidden_config in
  Encryption.encrypt ~where ~key ~iv:encryption_iv data ()

let save_encrypt ~where ~key syomurc () =
  let content = encrypt ~key syomurc () in
  Out_channel.with_open_bin where (fun oc -> output_string oc content)

let re_encrypt ~old_iv ~new_iv ~key path =
  let ( let* ) = Option.bind in
  let bytes = Util.Io.content_filename path () in
  let* file = Encryption.decrypt ~key ~iv:old_iv bytes () in
  let _ = Encryption.encrypt ~where:path ~key ~iv:new_iv file () in
  Some ()

(**
  [randomize_iv syomurc] regenerate the [iv] for each comics in [syomurc]
*)
let randomize_iv ~key syomurc =
  let scomics =
    List.map
      (fun comic ->
        let path =
          Filename.concat App.yomu_hidden_comics comic.encrypted_file_name
        in
        let new_iv = Encryption.random_iv () in
        let comic =
          match re_encrypt ~old_iv:comic.iv ~new_iv ~key path with
          | Some () ->
              { comic with iv = new_iv }
          | None ->
              let () = Printf.eprintf "Cannot randomize %s\n" path in
              comic
        in
        comic
      )
      syomurc.scomics
  in
  { scomics }

let decrypt ~key () =
  let path = App.yomu_hidden_config in
  match Encryption.decrpty_file ~key ~iv:encryption_iv path () with
  | Error exn ->
      raise exn
  | Ok None ->
      raise @@ Error.yomu_error
      @@ Error.DecryptionError
           (Printf.sprintf "Cannot decrypt : %s" App.hidden_config_name)
  | Ok (Some external_maneger_bytes) -> (
      match of_string external_maneger_bytes with
      | Ok data ->
          data
      | Error e ->
          raise @@ Error.(yomu_error @@ Error.DecryptionError e)
    )

let exclude_series serie syomurc =
  let scomics, excluded =
    syomurc.scomics |> List.partition (fun s -> not @@ List.mem s.serie serie)
  in
  ({ scomics }, excluded)

let excludes_vseries vsereis syomurc =
  let scomics, exclu =
    syomurc.scomics
    |> List.partition (fun s -> not @@ List.mem (s.volume, s.serie) vsereis)
  in
  ({ scomics }, exclu)

(**
  [filter_series regex series syomurc] filters [syomurc] by a list of series [series] and match its regex if [regex]
*)
let filter_series regex series syomurc =
  let matches item serie =
    let r =
      match regex with
      | true ->
          Str.regexp serie
      | false ->
          Str.regexp_string serie
    in
    Str.string_match r item.serie 0
  in
  let scomics =
    List.filter (fun item -> List.exists (matches item) series) syomurc.scomics
  in
  { scomics }

let rename_serie oldname newname syomurc =
  {
    scomics =
      syomurc.scomics
      |> List.map (fun s ->
             match s.serie = oldname with
             | true ->
                 { s with serie = newname }
             | false ->
                 s
         );
  }

let filter_vseries regex series syomurc =
  let matches item (index, serie) =
    let r =
      match regex with
      | true ->
          Str.regexp serie
      | false ->
          Str.regexp_string serie
    in
    item.volume = index && Str.string_match r item.serie 0
  in
  let scomics =
    List.filter (fun item -> List.exists (matches item) series) syomurc.scomics
  in
  { scomics }

let union lhs rhs = { scomics = lhs.scomics @ rhs.scomics }
let encrypt_format s = Printf.sprintf "%u --> %s" s.volume s.encrypted_file_name

let entries scomics =
  let module M = Map.Make (String) in
  let map = M.empty in
  let map =
    scomics.scomics
    |> List.fold_left
         (fun map s ->
           let name = encrypt_format s in
           match M.find_opt s.serie map with
           | None ->
               M.add s.serie [ name ] map
           | Some elt ->
               let elt = name :: elt in
               M.add s.serie elt map
         )
         map
  in
  M.bindings map

let decrypt_all ~key syomurc =
  let ( // ) = App.( // ) in
  syomurc.scomics
  |> List.map (fun s ->
         let path = App.yomu_hidden_comics // s.encrypted_file_name in
         match Encryption.decrpty_file ~key ~iv:s.iv path () with
         | Ok (Some data) ->
             let archive_path =
               Util.Io.dump_tmp ~name:s.encrypted_file_name
                 ~extension:App.tmp_extension data ()
             in
             let name = Printf.sprintf "%s-%u" s.serie s.volume in
             { archive_path; name }
         | Ok None ->
             raise @@ Error.yomu_error
             @@ Error.DecryptionError (Printf.sprintf "Cannot decrypt : %s" path)
         | Error e ->
             raise e
     )
  |> List.sort NamedArchive.compare_named_archive

let serie_exists serie syomurc =
  syomurc.scomics |> List.exists (fun scomic -> scomic.serie = serie)

let exists volume comic syomurc =
  syomurc.scomics
  |> List.exists (fun scomic -> scomic.volume = volume && scomic.serie = comic)

let add item syomurc = { scomics = item :: syomurc.scomics }
