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
  let () = Libyomu.Epub.epub_of_zip file in
  ()

let command = cmd run
