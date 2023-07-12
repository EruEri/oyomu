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

 

external enable_raw_mode: unit -> unit = "caml_enable_raw_mode"


type render_mode = 
  | NONE
  | Iterm 
  | Kitty 
  | SIXEL
  | SERVER

external c_comic_read: render_mode -> string list -> unit -> unit = "caml_read_comics"

let comic_read render_mode collection = 
  match render_mode with
  | SERVER -> failwith "todo"
  | (Iterm | Kitty | SIXEL | NONE) -> c_comic_read render_mode collection