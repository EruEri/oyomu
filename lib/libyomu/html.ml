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

let rec indent n =
  match n with
  | n when n < 0 ->
      String.empty
  | n ->
      Printf.sprintf "  %s" @@ indent @@ (n - 1)

let rec body_to_string level xml_body =
  match xml_body with
  | Xml.PCData d ->
      Printf.sprintf "%s%s%!" (indent level) d
  | Xml.Element (tag, _attributes, children) -> (
      match tag with
      | "p" | "li" ->
          children
          |> List.map (body_to_string @@ (level + 1))
          |> String.concat "\n"
      | _ ->
          children |> List.map (body_to_string @@ level) |> String.concat "\n"
    )

let body file =
  let ( let* ) = Option.bind in
  let html = Xml.parse_file file in
  let* head =
    List.find_map
      (fun xml ->
        let tag = Xml.tag xml in
        if tag = "body" then
          Some xml
        else
          None
      )
      (Xml.children html)
  in
  let () = print_endline @@ body_to_string 0 head in
  Some ()
