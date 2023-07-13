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

type 'a t = 'a list * 'a list


exception ZipperOutLeft
exception ZipperOutRight

let left = function
| [], _ -> raise ZipperOutLeft
| t::q, rhs -> q, t::rhs

let right = function
| _, [] -> raise ZipperOutRight
| lhs, t::q -> t::lhs, q

let is_at_start = function
| [], _ -> true
| _::_, _ -> false

let is_at_end = function
| _, [] -> true
| _, _::_ -> false

let of_list list: 'a t = 
  list, []

let of_list_end list: 'a t = 
  [], List.rev list

let top_left = function
| [], _ -> None
| t::_, _ -> Some t

let replace_current alt :'a t -> 'a t = function
| ([], _) as z -> z
| _::q, rhs -> alt::q, rhs  

let status = function
| lhs, rhs -> 
  let l = List.length lhs in 
  let r = List.length rhs in
  l, r, l + r



let rec action ?(ignored = false) f zipper = 
  let res = f ignored zipper in
  try match res with
  | `Right -> action f @@ left zipper
  | `Left -> action f @@ right zipper
  | `Ignore -> action ~ignored:true f zipper
  | `Quit -> res
  with _ -> res