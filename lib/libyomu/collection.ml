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


let check_exist path () = 
  match Sys.file_exists path with
  | true -> ()
  | false -> failwith @@ "File doesnt exist" ^ path

let space level = 
  String.init level (fun _ -> ' ')

let list level dir = 
  let afiles = Sys.readdir dir in
  let () = 
  afiles
    |> Array.iter (fun file -> 
      Printf.printf "%s|---- %s" (space level) file
    )
    in
  ()

(** [volumes comic] returns the path of the [comic] and its content *)
let volumes comic = 
  let open App in
  let path = comics_yomu // comic in
  match Sys.file_exists path with
  | true -> path, Some (Sys.readdir path)
  | false -> path, None

let convert_name index archive = 
  let extension = Filename.extension archive in
  Printf.sprintf "%u%s" index extension


let are_same_volume lhs rhs =
  let lhs = Filename.basename lhs in
  let rhs = Filename.basename rhs in
  rhs = lhs 

let add ~comic_name ~comic_dir ~comics index comic_archive = 
  let open App in
  let indexed_archive = convert_name index comic_archive in
  let path = comic_dir // indexed_archive in
  let () = match Array.exists (are_same_volume indexed_archive) comics with
    | false -> Util.Io.cp comic_archive path
    | true -> raise @@ Error.(yomu_error @@ Volume_already_existing {comic = comic_name; volume = index})
  in
  ()
  

let _list () = 
  let comics_path = App.comics_yomu in
  let () = check_exist comics_path () in
  let afiles = Sys.readdir comics_path in
  let () = Array.iter (Printf.printf "%s\n") afiles in 
  
  ()

