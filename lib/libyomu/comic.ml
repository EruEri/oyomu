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

(* treat string as byte vector *)
(* type data = string *)

type syomu_item = {
  iv : string;
  encrypted_file_name : string;
  serie : string;
  volume : int;
}
[@@deriving yojson]

type syomurc = { scomics : syomu_item list } [@@deriving yojson]
type page = { data : string }
type comic = { name : string; pages : page list }

type reading_item = (comic, string) Either.t
(** Either an unzip comic or it archive path *)

type reading_collection = reading_item list
type collection = comic list

module Syomu = struct
  let encryption_iv =
    String.init 12 (fun index -> Char.chr ((index + 1) mod 256))

  (** [create_item encrypted_file_name serie volume] create a new [syomu_item] with a random iv *)
  let create_item encrypted_file_name serie volume =
    { iv = Encryption.random_iv (); encrypted_file_name; serie; volume }

  let create = { scomics = [] }
  let to_string manager = manager |> syomurc_to_yojson |> Yojson.Safe.to_string
  let of_string bytes = bytes |> Yojson.Safe.from_string |> syomurc_of_yojson

  let encrypt ~key syomurc () =
    let data = to_string syomurc in
    let where = Option.some App.yomu_hidden_config in
    Encryption.encrypt ?where ~key ~iv:encryption_iv data ()

  let save_encrypt ~where ~key syomurc () =
    let content = encrypt ~key syomurc () in
    Out_channel.with_open_bin where (fun oc -> output_string oc content)

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

  let filter_serie serie syomurc =
    { scomics = syomurc.scomics |> List.filter (fun s -> s.serie = serie) }

  let filter_series series syomurc =
    {
      scomics = syomurc.scomics |> List.filter (fun s -> List.mem s.serie series);
    }

  let filter_vseries vsereis syomurc =
    {
      scomics =
        syomurc.scomics
        |> List.filter (fun s -> List.mem (s.volume, s.serie) vsereis);
    }

  let union lhs rhs = { scomics = lhs.scomics @ rhs.scomics }

  let decrypt_all ~key syomurc =
    let ( // ) = App.( // ) in
    syomurc.scomics
    |> List.map (fun s ->
           let path = App.yomu_hidden_comics // s.encrypted_file_name in
           match Encryption.decrpty_file ~key ~iv:s.iv path () with
           | Ok (Some data) ->
               Util.Io.dump_tmp ~name:s.encrypted_file_name
                 ~extension:App.tmp_extension data ()
           | Ok None ->
               raise @@ Error.yomu_error
               @@ Error.DecryptionError
                    (Printf.sprintf "Cannot decrypt : %s" path)
           | Error e ->
               raise e
       )

  let serie_exists serie syomurc =
    syomurc.scomics |> List.exists (fun scomic -> scomic.serie = serie)

  let exists volume comic syomurc =
    syomurc.scomics
    |> List.exists (fun scomic -> scomic.volume = volume && scomic.serie = comic)

  let add item syomurc = { scomics = item :: syomurc.scomics }
end

module CZip = struct
  let comic_of_zip archive =
    let zip = Zip.open_in archive in
    let entry = Zip.entries zip in
    let pages =
      entry
      |> List.map (fun entry ->
             let tmp_file, outchan =
               Filename.open_temp_file
                 (Filename.basename entry.Zip.filename)
                 App.tmp_extension
             in
             let () = prerr_endline entry.Zip.filename in
             let () = Zip.copy_entry_to_file zip entry tmp_file in
             let () = close_out outchan in
             let data =
               In_channel.with_open_bin tmp_file (fun ic ->
                   let data = Util.Io.read_file ic () in
                   { data }
               )
             in
             data
         )
    in
    let stripped_name =
      Filename.remove_extension @@ Filename.basename archive
    in
    let comic = { name = stripped_name; pages } in
    let () = Zip.close_in zip in
    comic
end
