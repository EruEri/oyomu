let epub_of_zip archive_path =
  let zip = Zip.open_in archive_path in
  let entries = Zip.entries zip in
  let () =
    List.iter (fun entry -> print_endline @@ Zip.read_entry zip entry) entries
  in
  ()
