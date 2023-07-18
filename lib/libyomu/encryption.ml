(**********************************************************************************************)
(*                                                                                            *)
(* This file is part of Hisoka                                                                *)
(* Copyright (C) 2023 Yves Ndiaye                                                             *)
(*                                                                                            *)
(* Hisoka is free software: you can redistribute it and/or modify it under the terms          *)
(* of the GNU General Public License as published by the Free Software Foundation,            *)
(* either version 3 of the License, or (at your option) any later version.                    *)
(*                                                                                            *)
(* Hisoka is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;        *)
(* without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR           *)
(* PURPOSE.  See the GNU General Public License for more details.                             *)
(* You should have received a copy of the GNU General Public License along with Hisoka.       *)
(* If not, see <http://www.gnu.org/licenses/>.                                                *)
(*                                                                                            *)
(**********************************************************************************************)

let uint_8_max = 256
let iv_size = 12

let aes_string_encrypt s () =
  let aes = Cryptokit.Hash.sha256 () in
  let _ = aes#add_string s in
  aes#result

let default_iv = String.init iv_size (fun _ -> Char.chr 0)

let random_iv () =
  String.init iv_size (fun _ -> uint_8_max |> Random.full_int |> Char.chr)

let encrypt ?(where = None) ~key ~iv data () =
  let e = Cryptokit.AEAD.(aes_gcm key ~iv Encrypt) in
  let encrypted_data = Cryptokit.auth_transform_string e data in
  match where with
  | None ->
      encrypted_data
  | Some where ->
      let () =
        Out_channel.with_open_bin where (fun channel ->
            output_string channel encrypted_data
        )
      in
      encrypted_data

let encrypt_file ?(where = None) ~key ~iv file () =
  match open_in_bin file with
  | exception exn ->
      Error exn
  | file ->
      let raw_data = Util.Io.read_file file () in
      let () = close_in file in
      Ok (encrypt ~where ~key ~iv raw_data ())

let decrypt ~key ~iv data () =
  let d = Cryptokit.AEAD.(aes_gcm key ~iv Decrypt) in
  let decrypted_data = Cryptokit.auth_check_transform_string d data in
  decrypted_data

let decrpty_file ~key ~iv file () =
  match open_in_bin file with
  | exception exn ->
      Error exn
  | file ->
      let raw_data = Util.Io.read_file file () in
      let () = close_in file in
      Ok (decrypt ~key ~iv raw_data ())
