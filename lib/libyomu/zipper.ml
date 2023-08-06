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
type move_kind = { absolute : bool; offset : int }

exception ZipperOutLeft
exception ZipperOutRight

let left = function [], _ -> raise ZipperOutLeft | t :: q, rhs -> (q, t :: rhs)

let right = function
  | _, [] ->
      raise ZipperOutRight
  | lhs, t :: q ->
      (t :: lhs, q)

let rec swipe n = function
  | (([] | _ :: []), _) as zipper when n > 0 ->
      zipper
  | (_, []) as zipper when n < 0 ->
      zipper
  | zipper when n = 0 ->
      zipper
  | zipper when n > 0 ->
      swipe (n - 1) (left zipper)
  | zipper ->
      swipe (n + 1) (right zipper)

let current_index zipper = List.length @@ snd zipper

let move { absolute; offset } zipper =
  match absolute with
  | false ->
      swipe offset zipper
  | true ->
      let current_page = current_index zipper in
      swipe (offset - current_page) zipper

let is_at_start = function [], _ -> true | _ :: _, _ -> false
let is_at_end = function _, [] -> true | _, _ :: _ -> false
let of_list list : 'a t = (list, [])
let of_list_end list : 'a t = ([], List.rev list)
let top_left = function [], _ -> None | t :: _, _ -> Some t

let replace_current alt : 'a t -> 'a t = function
  | ([], _) as z ->
      z
  | _ :: q, rhs ->
      (alt :: q, rhs)

let remove_current : 'a t -> 'a t = function
  | ([], _) as z ->
      z
  | _ :: q, rhs ->
      (q, rhs)

let status = function
  | lhs, rhs ->
      let l = List.length lhs in
      let r = List.length rhs in
      (l, r, l + r)

let rec action_alt f zipper =
  let new_zipper, res = f zipper in
  try
    match res with
    | `Left ->
        action_alt f @@ left new_zipper
    | `Right ->
        action_alt f @@ right new_zipper
    | `NoAction ->
        action_alt f new_zipper
    | `Quit ->
        res
  with _ -> res

let rec action ?(ignored = false) index f zipper =
  let res = f ignored index zipper in
  match res with
  | `Right as r -> (
      try action (index - 1) f @@ right zipper with _ -> r
    )
  | `Left as l -> (
      try action (index + 1) f @@ left zipper with _ -> l
    )
  | `Ignore ->
      action index ~ignored:true f zipper
  | `MovNoValue ->
      action index ~ignored:true f zipper
  | `ErrorIndexParsing ->
      action index ~ignored:true f zipper
  | `ReadError ->
      action index ~ignored:true f zipper
  | `GotoPage kind ->
      let zipper = move kind zipper in
      let cur_page = current_index zipper in
      action cur_page f @@ zipper
  | `GotoBook _ as e ->
      e
  | `Quit as q ->
      q
