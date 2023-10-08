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

let yomu_name = "yomu"
let tmp_extension = yomu_name
let ( // ) = Filename.concat
let xdg = Xdg.create ~env:Sys.getenv_opt ()
let xdg_data = Xdg.data_dir xdg
let xdg_config = Xdg.config_dir xdg
let comics_folder_name = "comics"
let hidden_folder_name = ".scomics"
let hidden_config_name = ".syomurc"
let config_file_name = "yomurc"
let yomu_share = xdg_data // yomu_name
let yomu_comics = yomu_share // comics_folder_name

(** [$XDG_DATA_HOME/share/yomu/.scomics/] *)
let yomu_hidden_comics = yomu_share // hidden_folder_name

(** [$XDG_DATA_HOME/share/yomu/.scomics/.syomurc]*)
let yomu_hidden_config = yomu_hidden_comics // hidden_config_name

(** [$XDG_CONFIG_HOME/yomu/]*)
let yomu_config = xdg_config // yomu_name

(** [$XDG_CONFIG_HOME/yomu/yomurc]*)
let yomu_config_file = yomu_config // config_file_name

let is_app_folder_exist () = Sys.file_exists yomu_share

module KeyBindingConst = struct
  let yomu_variable_make = Printf.sprintf "YOMU_%s"
  let key_variable_make s = yomu_variable_make @@ Printf.sprintf "%s_KEY" s

  let scale_variable_make axe pixel =
    let s_pixel =
      match pixel with
      | Cbindings.Chafa.CHAFA_PIXEL_MODE_ITERM2 ->
          "ITERM"
      | CHAFA_PIXEL_MODE_KITTY ->
          "KITTY"
      | CHAFA_PIXEL_MODE_SIXELS ->
          "SIXEL"
      | CHAFA_PIXEL_MODE_SYMBOLS ->
          "SYMBOL"
    in
    let s_axe = Util.Axe.to_string axe in
    yomu_variable_make @@ Printf.sprintf "SCALE_%s_%s" s_axe s_pixel

  let val_key ~default variable_name =
    let ( >>= ) = Option.bind in
    variable_name |> Sys.getenv_opt
    >>= (fun s -> try Option.some @@ String.get s 0 with _ -> None)
    |> Option.value ~default

  let variable_keep_unzip = yomu_variable_make "KEEP_UNZIPPED"
  let variable_scale_x = scale_variable_make AxeX
  let variable_scale_y = scale_variable_make AxeY
  let key_variable_next_page = key_variable_make "NEXT_PAGE"
  let key_variable_previous_page = key_variable_make "PREV_PAGE"
  let key_variable_goto_page = key_variable_make "GOTO_PAGE"
  let key_variable_goto_book = key_variable_make "GOTO_BOOK"
  let key_variable_quit = key_variable_make "QUIT"
  let val_next_page = val_key ~default:'l' key_variable_next_page
  let val_previous_page = val_key ~default:'h' key_variable_previous_page
  let val_goto_page = val_key ~default:'g' key_variable_goto_page
  let val_goto_book = val_key ~default:'b' key_variable_goto_book
  let val_quit = val_key ~default:'q' key_variable_quit
end

module Config = struct
  module M = Map.Make (String)

  type t = { variables : string M.t }

  let empty = { variables = M.empty }

  let to_string config =
    M.fold (Printf.sprintf "%s=%s\n%s") config.variables String.empty

  let save config =
    Out_channel.with_open_bin yomu_config_file
    @@ fun oc -> output_string oc @@ to_string config

  let create keep_unzipped =
    let s = Bool.to_string keep_unzipped in
    let variables = M.singleton KeyBindingConst.variable_keep_unzip s in
    let s = { variables } in
    s

  let parse ?keep_unzipped () =
    let ( let* ) = Result.bind in
    let ok = Result.ok in
    let err = Result.error in
    let* s =
      match Util.Io.content_filename yomu_config_file () with
      | s ->
          ok s
      | exception _ ->
          err `EReadConfig
    in
    let () = print_endline s in

    s |> String.split_on_char '\n'
    |> List.mapi (fun i v -> (i, v))
    |> List.fold_left
         (fun (acc, err_indexes) (index, elt) ->
           let line = String.split_on_char '=' elt in
           match line with
           | key :: (_ :: _ as values) ->
               let key = String.trim key in
               let value = String.concat "=" values in
               let value = String.trim value in
               (M.add key value acc, err_indexes)
           | [] | _ :: _ ->
               (acc, index :: err_indexes)
         )
         (M.empty, [])
    |> fun (variables, error) ->
    (let variables =
       match keep_unzipped with
       | Some b ->
           let sb = Bool.to_string b in
           M.add KeyBindingConst.variable_keep_unzip sb variables
       | None ->
           variables
     in
     ({ variables }, error)
    )
    |> ok

  let key key_name key_value ?override config =
    let ( >== ) = Option.bind in
    match override with
    | Some key ->
        key
    | None ->
        config.variables |> M.find_opt key_name
        >== (fun s -> try Some s.[0] with _ -> None)
        |> Option.value ~default:key_value

  let replace key_name value config =
    { variables = M.add key_name value config.variables }

  let default_quit = 'q'
  let default_next_page = 'l'
  let defauft_previous_page = 'h'
  let default_goto_page = 'g'
  let default_goto_book = 'b'
  let default_x_scale = 90
  let default_y_scale = 90

  let quit =
    let open KeyBindingConst in
    key key_variable_quit default_quit

  let replace_quit value =
    let open KeyBindingConst in
    replace key_variable_quit @@ Printf.sprintf "%c" value

  let next_page =
    let open KeyBindingConst in
    key key_variable_next_page default_next_page

  let replace_next_page value =
    let open KeyBindingConst in
    replace key_variable_next_page @@ Printf.sprintf "%c" value

  let previous_page =
    let open KeyBindingConst in
    key key_variable_previous_page defauft_previous_page

  let replace_previous_page value =
    let open KeyBindingConst in
    replace key_variable_previous_page @@ Printf.sprintf "%c" value

  let goto_page =
    let open KeyBindingConst in
    key key_variable_goto_page default_goto_page

  let replace_goto_page value =
    let open KeyBindingConst in
    replace key_variable_goto_page @@ Printf.sprintf "%c" value

  let goto_book =
    let open KeyBindingConst in
    key key_variable_goto_book default_goto_book

  let replace_goto_book value =
    let open KeyBindingConst in
    replace key_variable_goto_book @@ Printf.sprintf "%c" value

  let keep_unzipped config =
    let ( >== ) = Option.bind in
    config.variables
    |> M.find_opt KeyBindingConst.variable_keep_unzip
    >== bool_of_string_opt
    |> Option.value ~default:false

  (**
      [x_scale pixel config] searchs in [config] the value of [YOMU_SCALE_X_%PIXEL]
      if absent, or unparsable to [int] the default value is [90]
  *)
  let x_scale pixel config =
    let key_name = KeyBindingConst.scale_variable_make AxeX pixel in
    let ( >== ) = Option.bind in
    config.variables |> M.find_opt key_name >== int_of_string_opt
    |> Option.value ~default:default_x_scale

  let replace_x_scale mode value =
    replace
      (KeyBindingConst.scale_variable_make Util.Axe.AxeX mode)
      (string_of_int value)

  (**
      [y_scale pixel config] searchs in [config] the value of [YOMU_SCALE_Y_%PIXEL]
      if absent, or unparsable to [int] the default value is [90]
  *)
  let y_scale pixel config =
    let key_name = KeyBindingConst.scale_variable_make AxeY pixel in
    let ( >== ) = Option.bind in
    config.variables |> M.find_opt key_name >== int_of_string_opt
    |> Option.value ~default:default_y_scale

  let replace_y_scale mode value =
    replace
      (KeyBindingConst.scale_variable_make Util.Axe.AxeY mode)
      (string_of_int value)
end
