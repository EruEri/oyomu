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

open Error

type epub_content = { tmp_file : string; according_file : string }
type epub = epub_content list

module Convertion = struct
  let epub_of_zip archive_path =
    try
      let zip = Zip.open_in archive_path in
      let entry = Zip.entries zip in
      let files =
        List.filter_map
          (fun entry ->
            let ( let* ) = Option.bind in
            let* () =
              match entry.Zip.is_directory with
              | true ->
                  None
              | false ->
                  Some ()
            in
            let tmp_file, outchan =
              Filename.open_temp_file
                (Filename.basename entry.Zip.filename)
                App.tmp_extension
            in
            let () = prerr_endline entry.Zip.filename in
            let () = Zip.copy_entry_to_file zip entry tmp_file in
            let () = close_out outchan in
            Some { tmp_file; according_file = entry.filename }
          )
          entry
      in
      Some files
    with _ -> None
end

module Content = struct
  let content_opf = "content.opf"

  (**
      [find_content_opf epub] retuns the temporary filename associated with
      the file [content.opf]
  *)
  let find_content_opf : epub -> string option =
    List.find_map (fun { tmp_file; according_file } ->
        if String.ends_with ~suffix:content_opf tmp_file then
          Some according_file
        else
          None
    )
end

module Metadata = struct
  module MetadataMap = Map.Make (struct
    type t = string

    let compare = Stdlib.compare
  end)

  type xml_value = { attribues : (string * string) list; values : string list }

  type t = {
    title : string;
    language : string;
    identifier : string;
    others : xml_value MetadataMap.t;
  }

  let tag_name = "metadata"
  let compare = Stdlib.compare
  let find_opt key metadata = MetadataMap.find_opt key metadata.others

  let parse xml =
    let required_key key map =
      match MetadataMap.find_opt key map with
      | Some value ->
          let value =
            match value.values with t :: [] -> t | _ :: _ | [] -> failwith ""
          in
          value
      | None ->
          epub_error @@ MissingAttributes { attribut = key }
    in
    let found_tag = Xml.tag xml in
    let () =
      match tag_name = found_tag with
      | true ->
          ()
      | false ->
          epub_error @@ WrongExpectedTag found_tag
    in
    let map =
      Xml.fold
        (fun acc xml ->
          let ( $ ) = ( |> ) in
          let tag = Xml.tag xml in
          let attribues = Xml.attribs xml in
          let values =
            xml $ Xml.children
            $ List.filter_map (fun xml ->
                  match xml with
                  | Xml.PCData content ->
                      Some content
                  | Xml.Element _ ->
                      None
              )
          in
          let xml_value = { attribues; values } in
          let acc =
            match tag = "dc:identifier" with
            | false ->
                MetadataMap.add tag xml_value acc
            | true -> (
                match List.assoc_opt "id" attribues with
                | Some _ ->
                    MetadataMap.add tag xml_value acc
                | None ->
                    acc
              )
          in
          acc
        )
        MetadataMap.empty xml
    in

    let identifier = required_key "dc:identifier" map in
    let title = required_key "dc:title" map in
    let language = required_key "dc:language" map in
    { identifier; title; language; others = map }
end

module Manifest = struct
  type item = { id : string; href : string; media_type : string }
  type t = item list

  let tag_name = "manifest"

  let parse xml =
    let found_tag = Xml.tag xml in
    let () =
      match tag_name = found_tag with
      | true ->
          ()
      | false ->
          epub_error @@ WrongExpectedTag found_tag
    in
    List.rev
    @@ Xml.fold
         (fun acc xml ->
           let find_attrit a x =
             match Xml.attrib x a with
             | a ->
                 a
             | exception _ ->
                 epub_error @@ MissingAttributes { attribut = a }
           in
           let id = find_attrit "id" xml in
           let href = find_attrit "href" xml in
           let media_type = find_attrit "media-type" xml in
           { id; href; media_type } :: acc
         )
         [] xml
end

module Spine = struct
  type item_id = { idref : string }
  type t = item_id list

  let tag_name = "spine"

  let parse xml =
    let found_tag = Xml.tag xml in
    let () =
      match tag_name = found_tag with
      | true ->
          ()
      | false ->
          epub_error @@ WrongExpectedTag found_tag
    in
    List.rev
    @@ Xml.fold
         (fun acc xml ->
           let find_attrit a x =
             match Xml.attrib x a with
             | a ->
                 a
             | exception _ ->
                 epub_error @@ MissingAttributes { attribut = a }
           in
           let idref = find_attrit "idref" xml in
           { idref } :: acc
         )
         [] xml
end

module Guide = struct
  type reference = { r_type : string; href : string; title : string }
end

module Opf = struct
  type t = {
    metadata : Metadata.t;
    items : Manifest.t;
    spines : Spine.t;
    guide : Guide.reference list;
  }

  let parse sxml =
    let s = Xml.parse_string sxml in
    let childrens = Xml.children s in
    let metadata, manifest, spine, _guide =
      match childrens with
      | [ metadata; manifest; spine ] ->
          (metadata, manifest, spine, None)
      | [ metadata; manifest; spine; guide ] ->
          (metadata, manifest, spine, Some guide)
      | _ ->
          failwith "Wrong formated"
    in
    let metadata = Metadata.parse metadata in
    let items = Manifest.parse manifest in
    let spines = Spine.parse spine in
    let guide = [] in
    { metadata; items; spines; guide }

  let of_archive archive =
    let _epub =
      match Convertion.epub_of_zip archive with
      | Some epub ->
          epub
      | None ->
          failwith "Unziip error"
    in
    ()
end
