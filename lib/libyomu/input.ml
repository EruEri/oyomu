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

type error = No_matching_Password | Empty_Password

exception PassError of error

let confirm_password ~first_message ~confirm_message () =
  let pass1 = Cbindings.Libc.getpass first_message () in
  let pass2 = Cbindings.Libc.getpass confirm_message () in
  match pass1 = pass2 with
  | true ->
      Ok pass1
  | false ->
      Error No_matching_Password

let confirm_password_encrypted ~first_message ~confirm_message () =
  confirm_password ~first_message ~confirm_message ()
  |> Result.map Encryption.sha256_digest

let ask_password_encrypted ~prompt () =
  let pass = Cbindings.Libc.getpass prompt () in
  Encryption.sha256_digest pass

type _ input_behavior =
  | Continue : string option -> bool input_behavior
  | Stop_Wrong : string option -> bool option input_behavior

let rec confirm_choice :
    type a.
    continue_on_wrong_input:a input_behavior ->
    ?case_insensible:bool ->
    yes:char ->
    no:char ->
    prompt:string ->
    unit ->
    a =
 fun ~continue_on_wrong_input ?(case_insensible = true) ~yes ~no ~prompt () ->
  let string_transform =
    if case_insensible then
      String.lowercase_ascii
    else
      Fun.id
  in
  let () = Printf.printf "%s [%c/%c]: " prompt yes no in
  let choice = read_line () in
  let choice = string_transform choice in
  let s_yes = yes |> Char.escaped |> string_transform in
  let s_no = no |> Char.escaped |> string_transform in
  match continue_on_wrong_input with
  | Continue message ->
      if choice = s_yes then
        true
      else if choice = s_no then
        false
      else
        let () = Option.iter (Printf.printf "%s\n") message in
        confirm_choice ~continue_on_wrong_input ~case_insensible ~yes ~no
          ~prompt ()
  | Stop_Wrong message ->
      if choice = s_yes then
        Some true
      else if choice = s_no then
        Some false
      else
        let () = Option.iter (Printf.printf "%s\n") message in
        None
