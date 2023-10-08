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

let name = "config"
let pixels_modes = Read.pixels_modes

type t = {
  create : bool;
  next_page : char option option;
  previous_page : char option option;
  quit : char option option;
  goto_page : char option option;
  goto_book : char option option;
  x_scale : (Cbindings.Chafa.pixel_mode * int option) option;
  y_scale : (Cbindings.Chafa.pixel_mode * int option) option;
}

let create_term =
  Arg.(
    value & flag
    & info [ "n"; "new" ] ~doc:"Create the config if it doesn't exist"
  )

let next_page_term =
  Arg.(
    value
    & opt (some (some char)) None
    & info [ "next-page" ] ~docv:"KEY"
        ~doc:"Character that should be press if you want to go to the next page"
  )

let previous_page_term =
  Arg.(
    value
    & opt (some (some char)) None
    & info [ "prev-page" ] ~docv:"KEY"
        ~doc:
          "Character that should be press if you want to go to the previous \
           page"
  )

let quit_term =
  Arg.(
    value
    & opt (some (some char)) None
    & info [ "quit" ] ~docv:"KEY"
        ~doc:"Character that should be press if you want to exit $(mname)"
  )

let goto_page_term =
  Arg.(
    value
    & opt (some (some char)) None
    & info [ "gp"; "goto-page" ] ~docv:"KEY"
        ~doc:
          "Character that should be press if you want to go to a specific page"
  )

let goto_book_term =
  Arg.(
    value
    & opt (some (some char)) None
    & info [ "gb"; "goto-book" ] ~docv:"KEY"
        ~doc:
          "Character that should be press if you want to go to a specific book"
  )

let x_scale_term =
  let doc =
    Printf.sprintf "Percentage with each image is scaled on x (default: %u)"
      Libyomu.App.Config.default_x_scale
  in
  Arg.(
    value
    & opt (some (t2 ~sep:'=' (enum pixels_modes) (some int))) None
    & info [ "x-scale" ] ~docv:"PERCENT" ~doc
  )

let y_scale_term =
  let doc =
    Printf.sprintf "Percentage with each image is scaled on y (default: %u)"
      Libyomu.App.Config.default_y_scale
  in
  Arg.(
    value
    & opt (some (t2 ~sep:'=' (enum pixels_modes) (some int))) None
    & info [ "y-scale" ] ~docv:"PERCENT" ~doc
  )

let cmd_term run =
  let combine create next_page previous_page quit goto_page goto_book x_scale
      y_scale =
    run
    @@ {
         create;
         next_page;
         previous_page;
         quit;
         goto_page;
         goto_book;
         x_scale;
         y_scale;
       }
  in
  Term.(
    const combine $ create_term $ next_page_term $ previous_page_term
    $ quit_term $ goto_page_term $ goto_book_term $ x_scale_term $ y_scale_term
  )

let doc = "Configure $(mname)"

let man =
  [
    `S Manpage.s_description;
    `P "See and configure the keybinding and the image scaling";
    `P "The configuration file is located in your $XDG_CONFIG_HOME/yomu/yomurc";
    `P
      "This file is constituated of an succession of key value pairs splitted \
       by an equal";
    `P "Value $(b,should not) be surrounded be double quote (\")";
  ]

let cmd run =
  let info = Cmd.info name ~doc ~man in
  Cmd.v info @@ cmd_term run

(**
   [keybinding_conf f get variable config option]   
*)
let keybinding_conf f get variable config = function
  | None ->
      config
  | Some None ->
      let s = get config in
      let () = Printf.printf "%s = %c\n" variable s in
      config
  | Some (Some char) ->
      let c = f char config in
      let () = Printf.printf "%s -> %c\n" variable char in
      c

let scale_conf f get variable config = function
  | None ->
      config
  | Some (mode, None) ->
      let s = get mode config in
      let () = Printf.printf "%s = %u\n" (variable mode) s in
      config
  | Some (mode, Some int) ->
      let c = f mode int config in
      let () = Printf.printf "%s -> %u\n" (variable mode) int in
      c

let run cmd_config =
  let {
    create;
    next_page;
    previous_page;
    quit;
    goto_book;
    goto_page;
    x_scale;
    y_scale;
  } =
    cmd_config
  in
  let module AK = Libyomu.App.KeyBindingConst in
  let module AC = Libyomu.App.Config in
  let ( !! ) = function
    | Ok e ->
        e
    | Error e ->
        raise @@ Libyomu.Error.yomu_error e
  in
  let config, _ =
    match create with
    | false ->
        ( !! )
          (Libyomu.App.Config.parse ()
          |> Result.map_error @@ fun _ -> Libyomu.Error.YomuCreateConfigError
          )
    | true ->
        let _ =
          ( !! )
            (Result.map_error (fun i -> Libyomu.Error.Init_Error i)
            @@ Libyomu.Init.create_yomu_config ()
            )
        in
        (Libyomu.App.Config.empty, [])
  in
  let config =
    keybinding_conf AC.replace_next_page AC.next_page AK.key_variable_next_page
      config next_page
  in
  let config =
    keybinding_conf AC.replace_previous_page AC.previous_page
      AK.key_variable_previous_page config previous_page
  in
  let config =
    keybinding_conf AC.replace_quit AC.quit AK.key_variable_quit config quit
  in
  let config =
    keybinding_conf AC.replace_goto_page AC.goto_page AK.key_variable_goto_page
      config goto_page
  in
  let config =
    keybinding_conf AC.replace_goto_book AC.goto_book AK.key_variable_goto_book
      config goto_book
  in

  let config =
    scale_conf AC.replace_x_scale AC.x_scale AK.variable_scale_x config x_scale
  in

  let config =
    scale_conf AC.replace_y_scale AC.y_scale AK.variable_scale_y config y_scale
  in
  let () = Libyomu.App.Config.save config in
  ()

let command = cmd run
