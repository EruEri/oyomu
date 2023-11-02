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
  keep_unzipped : bool option;
  next_page : char option;
  previous_page : char option;
  quit : char option;
  goto_page : char option;
  goto_book : char option;
  x_scale : (Cbindings.Chafa.pixel_mode * int) option;
  y_scale : (Cbindings.Chafa.pixel_mode * int) option;
}

let create_term =
  Arg.(
    value & flag
    & info [ "n"; "new" ] ~doc:"Create the config if it doesn't exist"
  )

let keep_unzipped_term =
  Arg.(
    value
    & opt (some bool) None
    & info [ "keep-unzipped" ] ~docv:"true | false"
        ~doc:
          "Indicate whether unzipped comics should be kept in memory. If set, \
           unzipped comics won't be unzipped again if read again but cause a \
           larger memory consumtion"
  )

let next_page_term =
  Arg.(
    value
    & opt (some char) None
    & info [ "next-page" ] ~docv:"KEY"
        ~doc:"Character that should be press if you want to go to the next page"
  )

let previous_page_term =
  Arg.(
    value
    & opt (some char) None
    & info [ "prev-page" ] ~docv:"KEY"
        ~doc:
          "Character that should be press if you want to go to the previous \
           page"
  )

let quit_term =
  Arg.(
    value
    & opt (some char) None
    & info [ "quit" ] ~docv:"KEY"
        ~doc:"Character that should be press if you want to exit $(mname)"
  )

let goto_page_term =
  Arg.(
    value
    & opt (some char) None
    & info [ "gp"; "goto-page" ] ~docv:"KEY"
        ~doc:
          "Character that should be press if you want to go to a specific page"
  )

let goto_book_term =
  Arg.(
    value
    & opt (some char) None
    & info [ "gb"; "goto-book" ] ~docv:"KEY"
        ~doc:
          "Character that should be press if you want to go to a specific book"
  )

let spm = "PIXEL_MODE"

let x_scale_term =
  let doc =
    Printf.sprintf
      "%s : %s.\n      Percentage with each image is scaled on x (default: %u)"
      spm
      (Arg.doc_alts_enum Libyomu.Pixel.pixels_modes)
      Libyomu.App.Config.default_x_scale
  in
  let docv = Printf.sprintf "%s=PERCENT" spm in
  Arg.(
    value
    & opt (some (t2 ~sep:'=' (enum pixels_modes) int)) None
    & info [ "x-scale" ] ~docv ~doc
  )

let y_scale_term =
  let doc =
    Printf.sprintf
      "%s : %s.\n      Percentage with each image is scaled on y (default: %u)"
      spm
      (Arg.doc_alts_enum Libyomu.Pixel.pixels_modes)
      Libyomu.App.Config.default_y_scale
  in
  let docv = Printf.sprintf "%s=PERCENT" spm in
  Arg.(
    value
    & opt (some (t2 ~sep:'=' (enum pixels_modes) int)) None
    & info [ "y-scale" ] ~docv ~doc
  )

let cmd_term run =
  let combine create keep_unzipped next_page previous_page quit goto_page
      goto_book x_scale y_scale =
    run
    @@ {
         create;
         keep_unzipped;
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
    const combine $ create_term $ keep_unzipped_term $ next_page_term
    $ previous_page_term $ quit_term $ goto_page_term $ goto_book_term
    $ x_scale_term $ y_scale_term
  )

let doc = "Configure $(mname)"

let make_variable_section variable content =
  let variable = Printf.sprintf "$(b,%s)" variable in
  `I (variable, content)

let variable_description =
  [
    `I (Libyomu.App.KeyBindingConst.key_variable_next_page, "Next page key");
    `I
      ( Libyomu.App.KeyBindingConst.key_variable_previous_page,
        "Previous page key"
      );
    `I (Libyomu.App.KeyBindingConst.key_variable_quit, "Quit key");
    `I (Libyomu.App.KeyBindingConst.key_variable_goto_page, "Change page key");
    `I (Libyomu.App.KeyBindingConst.key_variable_goto_book, "Change book key");
  ]

let man =
  [
    `S Manpage.s_description;
    `P "See and configure the keybinding and the image scaling";
    `P "The configuration file is located in your XDG_CONFIG_HOME/yomu/yomurc";
    `P
      "This file is constituated of an succession of key value pairs splitted \
       by an equal";
    `P "Value $(b,should not) be surrounded be double quote (\")";
    `S Manpage.s_examples;
    `I
      ( "To set the x scaling of the sixel display",
        "$(iname) --x-scale sixel=($(b,VALUE))"
      );
    `I ("To set next page key to 'm'", "$(iname) --next-page m");
  ]

let cmd run =
  let info = Cmd.info name ~doc ~man in
  Cmd.v info @@ cmd_term run

(**
   [keybinding_conf f get variable config option]   
*)
let keybinding_conf f variable config = function
  | None ->
      config
  | Some char ->
      let c = f char config in
      let () = Printf.printf "%s -> %c\n" variable char in
      c

let scale_conf f variable config = function
  | None ->
      config
  | Some (mode, int) ->
      let c = f mode int config in
      let () = Printf.printf "%s -> %u\n" (variable mode) int in
      c

let bool_conf f variable config = function
  | None ->
      config
  | Some bool ->
      let c = f bool config in
      let () = Printf.printf "%s -> %b\n" variable bool in
      c

let run cmd_config =
  let {
    create;
    keep_unzipped;
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
  let base_config = config in
  let config =
    bool_conf AC.replace_keep_unzipped AK.variable_keep_unzip config
      keep_unzipped
  in
  let config =
    keybinding_conf AC.replace_next_page AK.key_variable_next_page config
      next_page
  in
  let config =
    keybinding_conf AC.replace_previous_page AK.key_variable_previous_page
      config previous_page
  in
  let config =
    keybinding_conf AC.replace_quit AK.key_variable_quit config quit
  in
  let config =
    keybinding_conf AC.replace_goto_page AK.key_variable_goto_page config
      goto_page
  in
  let config =
    keybinding_conf AC.replace_goto_book AK.key_variable_goto_book config
      goto_book
  in

  let config =
    scale_conf AC.replace_x_scale AK.variable_scale_x config x_scale
  in

  let config =
    scale_conf AC.replace_y_scale AK.variable_scale_y config y_scale
  in

  let () =
    (* Clever way to check if no set option were passed nor change the config file*)
    (* We chech the physical equality of config*)
    (*
       It assume that [keybinding_conf] [scale_conf] and [bool_scale] doesnt change [config] if
         it the option is [None]
    *)
    match base_config == config with
    | true ->
        let () = Printf.printf "%s\n" @@ Libyomu.App.Config.to_string config in
        ()
    | false ->
        ()
  in

  let () = Libyomu.App.Config.save config in
  ()

let command = cmd run
