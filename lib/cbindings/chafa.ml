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

type canvas_config
type canvas
type term_info

type pixel_mode =
  | CHAFA_PIXEL_MODE_SYMBOLS
  | CHAFA_PIXEL_MODE_SIXELS
  | CHAFA_PIXEL_MODE_KITTY
  | CHAFA_PIXEL_MODE_ITERM2

type pixel_type =
  (* 32 bits per pixel *)
  | CHAFA_PIXEL_RGBA8_PREMULTIPLIED
  | CHAFA_PIXEL_BGRA8_PREMULTIPLIED
  | CHAFA_PIXEL_ARGB8_PREMULTIPLIED
  | CHAFA_PIXEL_ABGR8_PREMULTIPLIED
  | CHAFA_PIXEL_RGBA8_UNASSOCIATED
  | CHAFA_PIXEL_BGRA8_UNASSOCIATED
  | CHAFA_PIXEL_ARGB8_UNASSOCIATED
  | CHAFA_PIXEL_ABGR8_UNASSOCIATED
  (* 24 bits per pixel *)
  | CHAFA_PIXEL_RGB8
  | CHAFA_PIXEL_BGR8
  | CHAFA_PIXEL_MAX

external chafa_canvas_config_new : unit -> canvas_config
  = "caml_chafa_canvas_config_new"

external chafa_canvas_config_set_pixel_mode :
  canvas_config -> pixel_mode -> unit
  = "caml_chafa_canvas_config_set_pixel_mode"

external chafa_canvas_config_set_geometry :
  canvas_config -> width:int -> height:int -> unit
  = "caml_chafa_canvas_config_set_geometry"

external chafa_canvas_config_set_cell_geometry :
  canvas_config -> width:int -> height:int -> unit
  = "caml_chafa_canvas_config_set_cell_geometry"

external chafa_canvas_new : ?config:canvas_config -> unit -> canvas
  = "caml_chafa_canvas_new"

external chafa_canvas_draw_all_pixels :
  canvas ->
  pixel_type ->
  bytes ->
  width:int ->
  height:int ->
  row_stride:int ->
  unit
  = "caml_chafa_canvas_draw_all_pixels_bytecode"
    "caml_chafa_canvas_draw_all_pixels"

external chafa_calc_canvas_geometry :
  width:int -> height:int -> zoom:bool -> stretch:bool -> float -> int * int
  = "caml_chafa_calc_canvas_geometry"
(**
    
*)

external chafa_canvas_print : ?term_info:term_info -> canvas -> string
  = "caml_chafa_canvas_print"

external chafa_canvas_unref : canvas -> unit = "caml_chafa_canvas_unref"

external chafa_canvas_config_unref : canvas_config -> unit
  = "caml_chafa_canvas_config_unref"
