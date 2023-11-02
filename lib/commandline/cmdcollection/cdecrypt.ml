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

open Cmdliner

let name = "decrypt"

type t = {
  outdir : string option;
  quiet : bool;
  all : string list;
  specifics : (int * string) list;
}

let outdir_term =
  Arg.(
    value
    & opt (some dir) None
    & info [ "d"; "output-dir" ] ~docv:"<OUTPUT_DIR>"
        ~doc:"Output directory of decrypted comics"
  )

let quiet_term =
  Arg.(
    value & flag
    & info [ "q"; "quiet" ]
        ~doc:"Don't echo comic name when successfully decrypted"
  )

let all_term =
  Arg.(
    value
    & opt (list string) []
    & info [ "a"; "all" ] ~docv:"COMIC"
        ~doc:
          "A separated list of all the comic where all the volumes should be \
           selected"
  )

let specifics =
  Arg.(
    value
    & pos_all (t2 ~sep:'.' int string) []
    & info [] ~docv:"<VOL.COMIC>" ~doc:"Select for each comic its volume"
  )

let cmd_term run =
  let combine outdir quiet all specifics =
    run @@ { outdir; quiet; all; specifics }
  in
  Term.(const combine $ outdir_term $ quiet_term $ all_term $ specifics)

let doc = "Decrypt encrypted comics"

let man =
  [
    `S Manpage.s_description;
    `P doc;
    `P "$(mname) should have been initialized with the $(mname)-init command";
  ]

let cmd run =
  let info = Cmd.info name ~doc ~man in
  Cmd.v info (cmd_term run)

let print_error message (sitem : Libyomu.Item.syomu_item) =
  Printf.eprintf "Error: Vol-%u, %s:\n   %s\n" sitem.volume sitem.serie message

let decrypt ~quiet ~outdir ~key all specifics =
  let syomurc = Libyomu.Syomu.decrypt ~key () in
  let filtered = Libyomu.Syomu.filter_series false all syomurc in
  let fspecifis = Libyomu.Syomu.filter_vseries false specifics syomurc in
  let syomurc = Libyomu.Syomu.union filtered fspecifis in
  let () =
    syomurc.scomics
    |> List.iter
       @@ fun sitem ->
       let open Libyomu.Item in
       let ( // ) = Libyomu.App.( // ) in
       let encrypted_path =
         Libyomu.App.yomu_hidden_comics // sitem.encrypted_file_name
       in
       let () =
         match
           Libyomu.Encryption.decrpty_file ~key ~iv:sitem.iv encrypted_path ()
         with
         | Error exn ->
             let printer = Printexc.to_string exn in
             print_error printer sitem
         | Ok None ->
             print_error "cannot decrypt" sitem
         | Ok (Some data) -> (
             let outname =
               Printf.sprintf "%s_Vol-%u.cbz" sitem.serie sitem.volume
             in
             let outpath = outdir // outname in
             try
               let () =
                 Out_channel.with_open_bin outpath (fun oc ->
                     output_string oc data
                 )
               in
               let () =
                 match quiet with
                 | true ->
                     ()
                 | false ->
                     Printf.printf "Successfully decrypted : %s\n%!" outname
               in
               ()
             with _ ->
               sitem
               |> print_error
                  @@ Printf.sprintf "Cannot write at path: %s" outpath
           )
       in
       ()
  in
  ()

let run cmd =
  let { outdir; quiet; all; specifics } = cmd in
  let () = Cmdcommon.check_yomu_initialiaze () in
  let () = Cmdcommon.check_yomu_hidden () in
  let key =
    Libyomu.Input.ask_password_encrypted ~prompt:Cmdcommon.password_prompt ()
  in
  let specifics =
    specifics |> List.filter (fun (_, serie) -> not @@ List.mem serie all)
  in
  let outdir = Option.value ~default:(Sys.getcwd ()) outdir in
  let () = decrypt ~quiet ~outdir ~key all specifics in
  ()

let command = cmd run
