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
        if String.ends_with ~suffix:content_opf according_file then
          Some tmp_file
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

  let item_of_id sid items = List.find_opt (fun { id; _ } -> id = sid) items
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

  type epub_opf = { opf : t; epub : epub }

  let parse_xml xml =
    let childrens = Xml.children xml in
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

  (**
      [parse_file filename] parses the file [filename] into [content.opf] speficitation
      @raise [YomuError] if parsing error occures or missing mendatory information
  *)
  let parse_file filename =
    let xml = Xml.parse_file filename in
    parse_xml xml

  let parse sxml =
    let s = Xml.parse_string sxml in
    parse_xml s

  let of_archive archive =
    let epub =
      match Convertion.epub_of_zip archive with
      | Some epub ->
          epub
      | None ->
          failwith "Unziip error"
    in
    let entry_file =
      match Content.find_content_opf epub with
      | Some file ->
          file
      | None ->
          failwith "Cannot find content.opf"
    in
    let opf =
      match parse_file entry_file with
      | content ->
          content
      | exception (YomuError (EpubError _) as e) ->
          raise e
    in
    { epub; opf }

  let item_of_id_opt id epub_opf = Manifest.item_of_id id epub_opf.opf.items

  (**
    [map_spine f epub_opf] call [f] on each reference pointed by [idref] in [spine] of [epub_opf]
  *)
  let map_spine f epub_opf =
    List.map
      (fun Spine.{ idref } -> f @@ item_of_id_opt idref epub_opf)
      epub_opf.opf.spines

  let find_file_opt filename epub_opf =
    List.find_map
      (fun { tmp_file; according_file } ->
        if according_file = filename then
          Some tmp_file
        else
          None
      )
      epub_opf.epub
end

module Page = struct
  type epub_page =
    | EPString of string
    (* Image path *)
    | EPImage of string

  let to_string = function
    | EPString s ->
        Printf.sprintf "Content :\n%s" s
    | EPImage i ->
        Printf.sprintf "Image url :\n%s" i

  let rec indent n =
    match n with
    | n when n < 0 ->
        String.empty
    | n ->
        Printf.sprintf "  %s" @@ indent @@ (n - 1)

  let rec body_to_page acc opf level xml_body =
    match xml_body with
    | Xml.PCData d ->
        let ( >>> ) = ( |> ) in
        let content = Printf.sprintf "%s%s%!" (indent level) d in
        let lines =
          content >>> String.split_on_char '\n'
          >>> List.map (fun s -> EPString s)
        in
        lines @ acc
    | Xml.Element (tag, _attributes, children) -> (
        match tag with
        | "p" | "li" ->
            let pages =
              List.map (body_to_page acc opf @@ (level + 1)) children
            in
            List.flatten pages
        | "img" ->
            let acc =
              match Xml.attrib xml_body "src" with
              | path ->
                  EPImage (Option.get @@ Opf.find_file_opt path opf) :: acc
              | exception _ ->
                  let () = prerr_string "To attrib src found" in
                  acc
            in
            acc
        | _ ->
            let pages = List.map (body_to_page acc opf @@ level) children in
            List.flatten pages
      )

  let body_to_page opf = body_to_page [] opf 0

  let body opf file =
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
    (* let () = print_endline @@ String.concat "\n" @@ List.map to_string @@ body_to_page head in *)
    Option.some @@ body_to_page opf head

  (*
      left string_content, right = image_path 
      assume   EPString s doesn't contains newline
    *)
  let consume_page (line, column) = function
    | EPImage i ->
        (Either.right i, 0)
    | EPString s ->
        let len = String.length s in
        let line_used = (len / column) + 1 in
        if line_used > line then
          (Either.left @@ Option.none, line)
        else
          (Either.left @@ Option.some s, line - line_used)

  let rec fold_content = function
    | [] | EPImage _ :: _ ->
        []
    | EPString s :: q ->
        s :: fold_content q
end
