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

open Cbindings

let debug_string content =
  Out_channel.with_open_text "debug" (fun oc -> Printf.fprintf oc "%s\n" content)

let debug_int n = n |> Int.to_string |> debug_string
let nb_channel = 4L
(* let scale = 0.90 *)

(* let draw_page comic_name ~n ~out_of page () =
   let open Termove in
   let winsize = Winsize.get () in
   let comic_name = String.sub comic_name 0 (max (String.length comic_name) winsize.ws_col) in
   let () = set_cursor_at 0 0 in *)

let base_fac = 90
let scale ?(fac = base_fac) n = n * fac / 100

let draw_error_message message =
  let w = Winsize.get () in
  let message_len = String.length message in
  let () =
    Termove.set_cursor_at (w.ws_row / 2) @@ ((w.ws_col / 2) - (message_len / 2))
  in
  Termove.draw_string message

let draw_image ~width ~height ~row_stride (winsize : Winsize.t) mode key_config
    pixels =
  let width = Int64.to_int width in
  let height = Int64.to_int height in

  let x_scale = Keys.x_scale mode key_config in
  let y_scale = Keys.y_scale mode key_config in

  let scaled_width, scaled_height =
    (scale ~fac:x_scale winsize.ws_col, scale ~fac:y_scale winsize.ws_row)
  in
  let config = Chafa.chafa_canvas_config_new () in
  let () = Chafa.chafa_canvas_config_set_pixel_mode config mode in
  let () =
    match mode with
    | Chafa.CHAFA_PIXEL_MODE_KITTY | Chafa.CHAFA_PIXEL_MODE_ITERM2 ->
        let () =
          (*
            12 24 arbitrairy value witch seem to work  
          *)
          Chafa.chafa_canvas_config_set_cell_geometry ~width:12 ~height:24
            config
        in
        ()
    | Chafa.CHAFA_PIXEL_MODE_SIXELS | CHAFA_PIXEL_MODE_SYMBOLS ->
        ()
  in
  let () =
    Chafa.chafa_canvas_config_set_geometry ~width:scaled_width
      ~height:scaled_height config
  in
  let canvas = Chafa.chafa_canvas_new ~config () in
  let () =
    Chafa.chafa_canvas_draw_all_pixels canvas CHAFA_PIXEL_RGBA8_UNASSOCIATED
      pixels ~width ~height ~row_stride:(Int64.to_int row_stride)
  in

  let content = Chafa.chafa_canvas_print canvas in
  let () = Termove.draw_string content in
  let () = Chafa.chafa_canvas_unref canvas in
  let () = Chafa.chafa_canvas_config_unref config in
  ()

let draw_page ~index comic_name mode key_config (page : Item.page) =
  let winsize = Winsize.get () in
  let () = Termove.redraw_empty () in
  let () = Termove.set_cursor_at 0 0 in
  let magick_wand = MagickWand.new_magick_wand () in
  let created = MagickWand.magick_read_image_blob magick_wand page.data in
  let () =
    match created with
    | false ->
        draw_error_message "Cannot create wand from file"
    | true ->
        let width = MagickWand.magick_get_image_width magick_wand in
        let height = MagickWand.magick_get_image_height magick_wand in
        let row_stride = Int64.mul width nb_channel in
        let pixels_len = Int64.(to_int @@ mul row_stride height) in
        let pixels = Bytes.create pixels_len in
        let exported =
          MagickWand.magick_export_image_pixels magick_wand ~x:0L ~y:0L
            ~columns:width ~rows:height "RGBA" CharPixel pixels
        in
        let () =
          match exported with
          | true ->
              draw_image winsize mode key_config ~width ~height ~row_stride
                pixels
          | false ->
              draw_error_message "cannot export"
        in
        ()
  in
  let () = Termove.set_cursor_at winsize.ws_row 0 in
  let () =
    Termove.draw_string
    @@ Util.UString.keep_n winsize.ws_col
    @@ Printf.sprintf "p: %u || %s" index comic_name
  in
  let () = MagickWand.destroy_magick_wand magick_wand in
  ()

let sub_first s =
  if s = String.empty then
    s
  else
    let len = String.length s in
    String.sub s 1 (len - 1)

let parser_move_kind content =
  match content = String.empty with
  | true ->
      let x = Error `MovNoValue in
      x
  | false ->
      let c = String.get content 0 in
      let absolute, offset =
        match c with
        | '+' ->
            let number_str = sub_first content in
            let number = int_of_string_opt number_str in
            (false, number)
        | '-' ->
            let number_str = sub_first content in
            let number =
              number_str |> int_of_string_opt
              |> Option.map (fun n -> ( ~- ) @@ abs n)
            in
            (false, number)
        | _ ->
            let n =
              content |> int_of_string_opt |> Option.map @@ fun n -> abs n - 1
            in
            (true, n)
      in
      offset
      |> Option.map (fun n -> Zipper.{ absolute; offset = n })
      |> Option.to_result ~none:`ErrorIndexParsing

let parser_page_movement content =
  let parser_res = parser_move_kind content in
  parser_res
  |> Result.map (fun kind -> `GotoPage kind)
  |> Result.fold ~ok:Fun.id ~error:Fun.id

let parse_book_movement content =
  let parser_res = parser_move_kind content in
  parser_res
  |> Result.map (fun kind -> `GotoBook kind)
  |> Result.fold ~ok:Fun.id ~error:Fun.id

let read_movement ~parser () =
  let () = Termove.enable_canonic () in
  let line = read_line () in
  let res =
    match String.length line with
    | n when n <= 0 ->
        `ReadError
    | _ ->
        let str_read = line in
        parser str_read
  in
  let () = Termove.disable_canonic () in
  res

let read_choice key_config () =
  let len = 1 in
  let bytes = Bytes.create len in
  let _ = Unix.read Unix.stdin bytes 0 len in
  let c = Bytes.get bytes 0 in
  match c with
  | c when c = Keys.previous_page key_config ->
      `Left
  | c when c = Keys.next_page key_config ->
      `Right
  | c when c = Keys.quit key_config ->
      `Quit
  | c when c = Keys.goto_book key_config ->
      read_movement ~parser:parse_book_movement ()
  | c when c = Keys.goto_page key_config ->
      read_movement ~parser:parser_page_movement ()
  | _ ->
      `Ignore

let update_array_comics configs index comic comics =
  match Keys.keep_unzipped configs with
  | true ->
      Array.set comics index (Either.Left comic)
  | false ->
      ()

let rec read ~ignored comic_index comics comic_name pixel_mode configs
    current_index pages =
  let current_page = try Some pages.(current_index) with _ -> None in
  match current_page with
  | None ->
      ()
  | Some page -> (
      let () =
        match ignored with
        | true ->
            ()
        | false ->
            let () =
              draw_page ~index:(current_index + 1) comic_name pixel_mode configs
                page
            in
            ()
      in
      match read_choice configs () with
      | `Quit ->
          ()
      | `GotoBook { absolute; offset } ->
          let new_index =
            match absolute with true -> offset | false -> offset + comic_index
          in
          read_collection pixel_mode configs new_index comics
      | `GotoPage { absolute; offset } ->
          let new_index =
            match absolute with
            | true ->
                offset
            | false ->
                offset + current_index
          in
          read ~ignored:false comic_index comics comic_name pixel_mode configs
            new_index pages
      | `Ignore | `MovNoValue | `ReadError | `ErrorIndexParsing ->
          read ~ignored:true comic_index comics comic_name pixel_mode configs
            current_index pages
      | `Left ->
          read ~ignored:false comic_index comics comic_name pixel_mode configs
            (current_index - 1) pages
      | `Right ->
          read ~ignored:false comic_index comics comic_name pixel_mode configs
            (current_index + 1) pages
    )

and read_collection pixel_mode configs comic_index comics =
  let current_page = try Some comics.(comic_index) with _ -> None in
  match current_page with
  | None ->
      ()
  | Some (item : (_, Item.named_archive) Either.t) -> (
      let comic_opt =
        match item with
        | Either.Left comic ->
            Some comic
        | Right { name; archive_path } ->
            archive_path |> Czip.comic_of_zip
            |> Option.map (fun (comic : Item.comic) ->
                   let comic = Item.{ comic with name } in
                   let () =
                     update_array_comics configs comic_index comic comics
                   in
                   let () = Gc.major () in
                   let () = Gc.compact () in
                   comic
               )
      in
      match comic_opt with
      | None ->
          read_collection pixel_mode configs (comic_index + 1) comics
      | Some { pages; name } ->
          read ~ignored:false comic_index comics name pixel_mode configs 0 pages
    )

let read_comics ~config mode (archives : Item.named_archive list) () =
  let () = Termove.start_window () in
  let () = Termove.hide_cursor () in
  let () = MagickWand.magick_wand_genesis () in

  (* let () = archives |> List.map (fun s -> s.Item.archive_path) |> String.concat "\n" |> debug_string in *)
  let collection = Array.of_list @@ List.map Either.right archives in
  let () = read_collection mode config 0 collection in

  let () = Termove.end_window () in
  let () = Termove.show_cursor () in
  let () = MagickWand.magick_wand_terminus () in
  let () = Collection.clear_tmp_files () in
  ()
