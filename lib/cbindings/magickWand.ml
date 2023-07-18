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

type t

type storage_type =
  | UndefinedPixel
  | CharPixel
  | DoublePixel
  | FloatPixel
  | LongPixel
  | LongLongPixel
  | QuantumPixel
  | ShortPixel

external magick_wand_genesis : unit -> unit = "caml_magick_wand_genesis"
external magick_wand_terminus : unit -> unit = "caml_magick_wand_terminus"
external new_magick_wand : unit -> t = "caml_new_magick_wand"
external destroy_magick_wand : t -> unit = "caml_destroy_magick_wand"

external magick_read_image_blob : t -> string -> bool
  = "caml_magick_read_image_blob"

external magick_get_image_width : t -> int64 = "caml_magick_get_image_width"
external magick_get_image_height : t -> int64 = "caml_magick_get_image_height"

external magick_export_image_pixels :
  t ->
  x:int64 ->
  y:int64 ->
  columns:int64 ->
  rows:int64 ->
  string ->
  storage_type ->
  bytes ->
  bool
  = "caml_magick_export_image_pixels_bytecode" "caml_magick_export_image_pixels"
