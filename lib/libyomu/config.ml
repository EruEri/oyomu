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
let version = "0.3.1"
let tmp_extension = yomu_name
let ( // ) = Filename.concat
let xdg = Xdg.create ~env:Sys.getenv_opt ()
let xdg_data = Xdg.data_dir xdg
let xdg_config = Xdg.config_dir xdg
let comics_folder_name = "comics"
let hidden_folder_name = ".scomics"
let hidden_config_name = ".syomurc"
let config_file_name = "yomurc"
let yomu_share = xdg_data // yomu_name

(** [$XDG_DATA_HOME/share/yomu/comics/] *)
let yomu_comics = yomu_share // comics_folder_name

(** [$XDG_DATA_HOME/share/yomu/.scomics/] *)
let yomu_hidden_comics = yomu_share // hidden_folder_name

(** [$XDG_DATA_HOME/share/yomu/.scomics/.syomurc]*)
let yomu_hidden_config = yomu_hidden_comics // hidden_config_name

(** [$XDG_CONFIG_HOME/yomu/]*)
let yomu_config = xdg_config // yomu_name

(** [$XDG_CONFIG_HOME/yomu/yomurc]*)
let yomu_config_file = yomu_config // config_file_name

let is_app_folder_exist () = Sys.file_exists yomu_share
