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

type named_archive = { name : string; archive_path : string }
type reading_collection = reading_item list
type collection = comic list
