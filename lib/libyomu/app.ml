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


let yomu_name = "yomu"
let ( // ) = Filename.concat
let xdg = Xdg.create ~env:Sys.getenv_opt ()
let xdg_data = Xdg.data_dir xdg
let xdg_config = Xdg.config_dir xdg

let comics_folder_name = "comics"

let share_yomu = xdg_data // yomu_name

let comics_yomu = share_yomu // comics_folder_name

let config_yomu = xdg_config // yomu_name

let is_app_folder_exist () =
  Sys.file_exists share_yomu

let check_app_initialized () =
  let () =
    if not @@ is_app_folder_exist () then
      raise @@ Error.yomu_error @@ Yomu_Not_Initialized
  in
  ()