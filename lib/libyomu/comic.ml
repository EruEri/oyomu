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

type page = {
  data: string
}

type comic = {
  name: string;
  pages: page list
}

type collection = comic list


let comic_of_zip archive = 
  let zip = Zip.open_in archive in
  let entry = Zip.entries zip in
  let pages = entry |> List.map (fun entry -> 
    let tmp_file, outchan = Filename.open_temp_file entry.Zip.filename "" in
    let () = Zip.copy_entry_to_file zip entry tmp_file in
    let () = close_out outchan in
    let data = In_channel.with_open_bin tmp_file (fun ic -> 
       let data = Util.Io.read_file ic () in
       { data }
    ) in
    data
  ) 
  in
  let stripped_name = Filename.basename archive in
  let comic = {name = stripped_name; pages} in
  let () = Zip.close_in zip in
  comic