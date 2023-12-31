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

  let x_scale = App.Config.x_scale mode key_config in
  let y_scale = App.Config.y_scale mode key_config in

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
  | c when c = App.Config.previous_page key_config ->
      `Right
  | c when c = App.Config.next_page key_config ->
      `Left
  | c when c = App.Config.quit key_config ->
      `Quit
  | c when c = App.Config.goto_book key_config ->
      read_movement ~parser:parse_book_movement ()
  | c when c = App.Config.goto_page key_config ->
      read_movement ~parser:parser_page_movement ()
  | _ ->
      `Ignore

let read_page comic_name mode key_config ignored index zipper =
  let index = index + 1 in
  let (page : Item.page option) = Zipper.top_left zipper in
  match page with
  | None ->
      `Left
  | Some page ->
      let () =
        match ignored with
        | true ->
            ()
        | false ->
            let () = draw_page ~index comic_name mode key_config page in
            ()
      in
      let option = read_choice key_config () in
      option

let read_item mode key_config (item : ('a, Item.named_archive) Either.t) =
  let ( let* ) = Option.bind in
  let* (Item.{ pages; name } as c) =
    match item with
    | Either.Left comic ->
        Some comic
    | Either.Right { name; archive_path } ->
        let* comic = Czip.comic_of_zip archive_path in
        let () = Gc.major () in
        let () = Gc.compact () in
        Some { comic with name }
  in

  let z_pages = Zipper.of_list pages in
  let res = Zipper.action 0 (read_page name mode key_config) z_pages in
  Some (c, res)

let read_collection mode config =
  Zipper.action_alt (fun zipper ->
      let current_opt = Zipper.top_left zipper in
      match current_opt with
      | None ->
          (zipper, `Left)
      | Some either_comic ->
          let zipper, res =
            match read_item mode config either_comic with
            | None ->
                (Zipper.remove_current zipper, `NoAction)
            | Some (comic, res) ->
                let zipper =
                  match either_comic with
                  | Either.Right _ -> (
                      match App.Config.keep_unzipped config with
                      | true ->
                          Zipper.replace_current (Either.left comic) zipper
                      | false ->
                          zipper
                    )
                  | Either.Left _ ->
                      zipper
                in
                let zipper, res =
                  match res with
                  | (`Left | `Quit | `Right) as e ->
                      (zipper, e)
                  | `GotoBook kind ->
                      let n, res =
                        match kind.Zipper.offset with
                        | n when n < 0 && not kind.absolute ->
                            (1, `Right)
                        | n when n > 0 && not kind.absolute ->
                            (-1, `Left)
                        | _ ->
                            (0, `NoAction)
                      in
                      (* Need this offset [n] since the since [res] will also move the zipper by one so we remove one by the movement *)
                      let kind = { kind with offset = kind.offset + n } in
                      let zipper = Zipper.move kind zipper in
                      (zipper, res)
                in
                (zipper, res)
          in
          (zipper, res)
  )

let read_comics ~config mode (archives : Item.named_archive list) () =
  let () = Termove.start_window () in
  let () = Termove.hide_cursor () in
  let () = MagickWand.magick_wand_genesis () in

  (* let () = archives |> List.map (fun s -> s.Item.archive_path) |> String.concat "\n" |> debug_string in *)
  let collection = List.map Either.right archives in
  let z_collections = Zipper.of_list collection in

  let _side = read_collection mode config z_collections in

  let () = Termove.end_window () in
  let () = Termove.show_cursor () in
  let () = MagickWand.magick_wand_terminus () in
  let () = Collection.clear_tmp_files () in
  ()
