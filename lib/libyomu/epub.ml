let content_opf = "content.opf"

let epub_of_zip archive_path =
  let zip = Zip.open_in archive_path in
  let entries = Zip.entries zip in
  let content_entry = Zip.find_entry zip content_opf in
  let _content_content = Zip.read_entry zip content_entry in
  let () =
    List.iter
      (fun entry ->
        print_endline
        @@ Printf.sprintf "%s\ndir : %b\n"
             Zip.(entry.filename)
             entry.is_directory
      )
      entries
  in
  let () = Zip.close_in zip in
  ()

let opf_content_of_zip archive_path =
  let zip = Zip.open_in archive_path in
  let content_entry = Zip.find_entry zip content_opf in
  let content_content = Zip.read_entry zip content_entry in
  let () = Zip.close_in zip in
  content_content

type epub_error =
  | UnknownError of (int * int)
  | MissingMendatoryKey of { section : string; key : string }
  | MissingAttributes of { attribut : string }
  | WrongSection of string

exception EpubError of epub_error

let string_of_epub_error =
  let open Printf in
  function
  | UnknownError (i, o) ->
      Printf.sprintf "Loc error %u %u" i o
  | MissingMendatoryKey { section; key } ->
      sprintf "\"%s\" : missing mendatory key : \"%s\"" section key
  | MissingAttributes { attribut } ->
      sprintf "Missing attribut : \"%s\"" attribut
  | WrongSection s ->
      sprintf "Wrong section : \"%s\"" s

let register_exn =
  Printexc.register_printer (function
    | EpubError epub_error ->
        Option.some @@ string_of_epub_error epub_error
    | _ ->
        None
    )

let epub_error e = raise @@ EpubError e

module Metadata = struct
  module MetadataMap = Map.Make (struct
    type t = string

    let compare = Stdlib.compare
  end)

  type t = {
    title : string;
    language : string;
    identifier : string;
    others : string MetadataMap.t;
  }

  let section_xml_name = "metadata"
  let compare = Stdlib.compare
  let find_opt key metadata = MetadataMap.find_opt key metadata.others

  let parse xml =
    let properties = Xml.children xml in
    List.iter
      (fun s ->
        let values = Xml.children s in
        let () =
          List.iter (fun ss -> Printf.printf "%s\n" @@ Xml.to_string ss) values
        in
        Printf.printf "%s\n" @@ Xml.to_string s
      )
      properties
end

module Manifest = struct
  type item = { id : string; href : string; media_type : string }
  type t = item list
end

module Spine = struct
  type item_id = { idref : string }
  type t = item_id list
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
    let metadata, _manifest, _spine, _guide =
      match childrens with
      | [ metadata; manifest; spine ] ->
          (metadata, manifest, spine, None)
      | [ metadata; manifest; spine; guide ] ->
          (metadata, manifest, spine, Some guide)
      | _ ->
          failwith "Wrong formated"
    in
    let _ = Metadata.parse metadata in
    ()
  (* let i_opf input =
     let () = EpubUtil.accpet_dtd None input in
     let () = EpubUtil.accept_tag_start (("", "package"), []) input in
     let metadata = Metadata.i_metadata input in
     let items = Manifest.i_manifest input in
     let spines = Spine.i_spine input in
     let guide = [] in
     let () = EpubUtil.take_end input in
     { metadata; items; spines; guide } *)
end
