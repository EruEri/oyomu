open Cmdliner

let name = "epub"

type t = { file : string }

let file_term =
  let linfo =
    Arg.info [] ~docv:"<FILES.epub>"
      ~doc:"Archive of the comic. The archives must be epub zip archive"
  in
  Arg.(required & pos 0 (some non_dir_file) None & linfo)

let cmd_term run =
  let combine file = run @@ { file } in
  Term.(const combine $ file_term)

let cmd_doc = "Test epub"
let cmd_man = [ `S Manpage.s_description; `P "Test epub parsing" ]

let cmd run =
  let info = Cmd.info name ~doc:cmd_doc ~man:cmd_man in
  Cmd.v info (cmd_term run)

let run cmd =
  let { file } = cmd in
  let module E = Libyomu.Epub in
  let epub_opf = E.Opf.of_archive file in
  let f =
    E.Opf.map_spine (fun item_opt ->
        let opt =
          Option.map
            (fun item ->
              let tmp_file =
                match E.Opf.find_file_opt item.E.Manifest.href epub_opf with
                | Some f ->
                    f
                | None ->
                    failwith "No file tmp solus"
              in
              let () = Printf.printf "href = %s\n" item.E.Manifest.href in
              Option.get @@ E.Page.body epub_opf tmp_file
            )
            item_opt
        in
        Option.to_list opt
    )
  in

  let pages = List.flatten @@ List.flatten @@ f epub_opf in
  let _ = Libyomu.Drawing.render_epub ~config:() () pages () in
  (* let content = Libyomu.Epub.opf_content_of_zip file in
     let _ = Libyomu.Epub.Opf.parse @@ content in
     let content = Libyomu.Epub.epub_of_zip file in *)
  ()

let command = cmd run
