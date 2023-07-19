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

let check_yomu_hidden () =
  match Libyomu.Init.check_yomu_hidden () with
  | Ok () ->
      ()
  | Error e ->
      raise @@ Libyomu.Error.(yomu_error @@ Missing_init_file e)

let check_yomu_initialiaze () =
  match Libyomu.Init.check_yomu_initialiaze () with
  | Ok () ->
      ()
  | Error _ ->
      raise @@ Libyomu.Error.(yomu_error @@ Yomu_Not_Initialized)
