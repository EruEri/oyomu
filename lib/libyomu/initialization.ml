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

open Util.FileSys

(** [create_yomu_share ()] create the folder [ $XDG_.../share/yomu] *)
let create_yomu_share () =
  create_folder ~on_error:(Error.Create_folder App.share_yomu) App.share_yomu

(** 
  [create_yomu_comic ()] create the folder [comic] in [$XDG_.../share/yomu] so 
  [$XDG_.../share/yomu/comics]
*)
let create_yomu_comics () =
  create_folder ~on_error:(Error.Create_folder App.comics_yomu) App.comics_yomu
