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

let sixel_facs =
  match Cbindings.OsInfo.macos with true -> (2, 4) | false -> (1, 2)

let sixel_x_fac = fst sixel_facs
let sixel_y_fac = snd sixel_facs

let draw_error_message message =
  let w = Winsize.get () in
  let message_len = String.length message in
  let () =
    Termove.set_cursor_at (w.ws_row / 2) @@ ((w.ws_col / 2) - (message_len / 2))
  in
  Termove.draw_string message

let draw_image (winsize : Winsize.t) mode ~width ~height ~row_stride pixels =
  let width = Int64.to_int width in
  let height = Int64.to_int height in

  let scaled_width, scaled_height =
    match mode with
    | Chafa.CHAFA_PIXEL_MODE_SIXELS ->
        (sixel_x_fac * scale winsize.ws_col, sixel_y_fac * scale winsize.ws_row)
    | _ ->
        (scale winsize.ws_col, scale winsize.ws_row)
  in
  let config = Chafa.chafa_canvas_config_new () in
  let () = Chafa.chafa_canvas_config_set_pixel_mode config mode in
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

let draw_page ~index comic_name mode (page : Comic.page) =
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
              draw_image winsize mode ~width ~height ~row_stride pixels
          | false ->
              draw_error_message "cannot export"
        in
        ()
  in
  let () = Termove.set_cursor_at winsize.ws_row 0 in
  let () =
    Termove.draw_string @@ Printf.sprintf "p: %u || %s" index comic_name
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
            let n = content |> int_of_string_opt |> Option.map abs in
            (true, n)
      in
      offset
      |> Option.map (fun n -> Zipper.{ absolute; offset = n - 1 })
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

let read_choice () =
  let len = 1 in
  let bytes = Bytes.create len in
  let _ = Unix.read Unix.stdin bytes 0 len in
  let c = Bytes.get bytes 0 in
  match c with
  | 'j' | 'J' ->
      `Left
  | 'l' | 'L' ->
      `Right
  | 'q' | 'Q' ->
      `Quit
  | 'b' ->
      read_movement ~parser:parse_book_movement ()
  | 'g' ->
      read_movement ~parser:parser_page_movement ()
  | _ ->
      `Ignore

let read_page comic_name mode ignored index zipper =
  let index = index + 1 in
  let (page : Comic.page option) = Zipper.top_left zipper in
  match page with
  | None ->
      `Right
  | Some page ->
      let () =
        match ignored with
        | true ->
            ()
        | false ->
            let () = draw_page ~index comic_name mode page in
            ()
      in
      let option = read_choice () in
      option

let read_item mode (item : ('a, Comic.named_archive) Either.t) =
  let (Comic.{ pages; name } as c) =
    match item with
    | Either.Left comic ->
        comic
    | Either.Right { name; archive_path } ->
        let comic = Comic.CZip.comic_of_zip archive_path in
        { comic with name }
  in

  let z_pages = Zipper.of_list pages in
  let res = Zipper.action 0 (read_page name mode) z_pages in
  (c, res)

let read_collection mode =
  Zipper.action_alt (fun zipper ->
      let current_opt = Zipper.top_left zipper in
      match current_opt with
      | None ->
          (zipper, `Right)
      | Some either_comic ->
          let comic, res = read_item mode either_comic in
          let zipper =
            match either_comic with
            | Either.Right _ ->
                Zipper.replace_current (Either.left comic) zipper
            | Either.Left _ ->
                zipper
          in
          let zipper, res =
            match res with
            | (`Left | `Quit | `Right) as e ->
                (zipper, e)
            | `GotoBook kind ->
                let res =
                  match kind.Zipper.offset <= 0 with
                  | true ->
                      `Left
                  | false ->
                      `Right
                in
                let zipper = Zipper.move kind zipper in
                (zipper, res)
          in
          (zipper, res)
  )

let read_comics mode (archives : Comic.named_archive list) () =
  let () = Termove.start_window () in
  let () = Termove.hide_cursor () in
  let () = MagickWand.magick_wand_genesis () in

  let collection = List.map Either.right archives in
  let z_collections = Zipper.of_list collection in

  let _side = read_collection mode z_collections in

  let () = Termove.end_window () in
  let () = Termove.show_cursor () in
  let () = MagickWand.magick_wand_terminus () in
  let () = Collection.clear_tmp_files () in
  ()
