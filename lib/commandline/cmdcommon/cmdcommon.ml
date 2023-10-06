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

let check_yomu_hidden () =
  match Libyomu.Init.check_yomu_hidden () with
  | Ok () ->
      ()
  | Error e ->
      raise @@ Libyomu.Error.(yomu_error @@ Missing_init_file e)

let check_yomu_initialiaze () =
  match Libyomu.Init.check_yomu_initialiaze () with
  | Ok () ->
      ()
  | Error _ ->
      raise @@ Libyomu.Error.(yomu_error @@ Yomu_Not_Initialized)

let keep_unzipped_term =
  Arg.(
    value
    & opt (some bool) None
    & info [ "keep-unzipped" ]
        ~doc:
          "Indicate whether unzipped comics should be kept in memory. If set, \
           unzipped comics won't be unzipped again if read again but cause a \
           larger memory consumtion"
  )

let filter_dotfile ~path s =
  match String.starts_with ~prefix:"." s with
  | true ->
      let () =
        try Util.FileSys.rmrf (Filename.concat path s) () with _ -> ()
      in
      None
  | false ->
      Some s

let password_prompt = "Enter the master password : "

let ask_password_if_encrypted encrypted () =
  match encrypted with
  | false ->
      None
  | true ->
      let () = check_yomu_hidden () in
      let key =
        Option.some
        @@ Libyomu.Input.ask_password_encrypted ~prompt:password_prompt ()
      in
      key

let make_variable_section variable content =
  let variable = Printf.sprintf "$(b,%s)" variable in
  `I (variable, content)

let variable_description =
  Printf.sprintf
    "If this environment variable is present, the %s is mapped to the first \
     letter of this environment variable"

let var_next_page =
  make_variable_section Libyomu.App.KeyBindingConst.key_variable_next_page
  @@ variable_description "next page key"

let var_previous_page =
  make_variable_section Libyomu.App.KeyBindingConst.key_variable_previous_page
  @@ variable_description "previous page key"

let var_quit =
  make_variable_section Libyomu.App.KeyBindingConst.key_variable_quit
  @@ variable_description "quit key"

let var_goto_page =
  make_variable_section Libyomu.App.KeyBindingConst.key_variable_goto_page
  @@ variable_description "goto page key"

let var_goto_book =
  make_variable_section Libyomu.App.KeyBindingConst.key_variable_goto_book
  @@ variable_description "goto book key"

let read_common_description =
  [
    `S "KEY BINDINGS";
    `P "This section presents the default key bindings";
    `Noblank;
    `P
      (Printf.sprintf
         "see $(b,%s) section to see which environment variable maps which key"
         Manpage.s_environment
      );
    `I ("To go to the next page", "Press $(b,'l')");
    `I ("To go to the precious page", "Press $(b,'j')");
    `I ("To quit", "Press $(b,'q')");
    `I ("To move to the page 10", "Press $(b,'g10')");
    `I ("To move 10 pages forward", "Press $(b,'g+10')");
    `I ("To move 10 pages backward", "Press $(b,'g-10')");
    `P
      "If you had loaded multiple comics, you can do the same movement than \
       with the pages but with the book by replacing the 'g' by 'b'";
    `S Manpage.s_environment;
    var_next_page;
    var_previous_page;
    var_quit;
    var_goto_page;
    var_goto_book;
  ]
