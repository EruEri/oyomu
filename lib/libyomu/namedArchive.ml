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

open Item

let compare_named_archive lhs rhs =
  let ( <=> ) = compare in
  let ( >== ) = Option.bind in
  let head_opt = function [] -> None | t :: _ -> Some t in
  let int_name { archive_path = _; name } =
    name |> Filename.basename |> Filename.remove_extension
    |> String.split_on_char '-' |> List.rev |> head_opt >== int_of_string_opt
    |> Option.value ~default:1
  in
  int_name lhs <=> int_name rhs
