////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
// This file is part of Yomu: A comic reader                                                  //
// Copyright (C) 2023 Yves Ndiaye                                                             //
//                                                                                            //
// Yomu is free software: you can redistribute it and/or modify it under the terms            //
// of the GNU General Public License as published by the Free Software Foundation,            //
// either version 3 of the License, or (at your option) any later version.                    //
//                                                                                            //
// Yomu is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;          //
// without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR           //
// PURPOSE.  See the GNU General Public License for more details.                             //
// You should have received a copy of the GNU General Public License along with Yomu.         //
// If not, see <http://www.gnu.org/licenses/>.                                                //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////



#include <sys/ttycom.h>
#define CAML_NAME_SPACE

#include <chafa.h>
#include <MagickWand/MagickWand.h>
#include "MagickCore/magick-type.h"
#include "MagickCore/pixel.h"
#include "callback.h"
#include "caml/memory.h"
#include "display.h"
#include "caml/misc.h"
#include "caml/mlvalues.h"
#include <stddef.h>
#include <sys/ioctl.h>
#include <stdlib.h>
#include "termove.h"
#include <unistd.h>
#include <termios.h>

#define RGBA "RGBA"
#define NCHANNEL (4)
#define SCALE (0.93)

#define NO_FILE "The list is empty, Press 'q' to quit"
#define NO_IMAGE_FILE "Not an image file"


typedef enum {
    NO_ERROR,
    MALLOC_FAIL,
    MAGICKNULL,
    MAGICK_EXPORT_FAIl,
} exit_status_t;

struct termios raw;
struct termios orig_termios;

void enableRawMode();
void disableRawMode();
void end_window();

void enableRawMode() {
    tcgetattr(STDIN_FILENO, &orig_termios);
    struct termios raw = orig_termios;
  
    raw.c_lflag &= ~(ECHO | ICANON);
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
}

void disableRawMode() {
  raw.c_lflag |= (ECHO | ICANON);  
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
}

void start_window() {
    enableRawMode();
    write(STDOUT_FILENO, NEW_SCREEN_BUFF_SEQ, strlen(NEW_SCREEN_BUFF_SEQ));
}

void handle_sigint(int signo) {
    disableRawMode();
    end_window();
}

void set_pixel_mode(ChafaCanvasConfig* config, render_mode_t mode) {
    switch (mode) {
    case ITERM:
        // chafa_canvas_config_set_canvas_mode(config, CHAFA_CANVAS_MODE_INDEXED_256);
        chafa_canvas_config_set_pixel_mode(config, CHAFA_PIXEL_MODE_ITERM2);
        break;
    case KITTY:
        chafa_canvas_config_set_pixel_mode(config, CHAFA_PIXEL_MODE_KITTY);
        break;
    case SIXEL:
        chafa_canvas_config_set_pixel_mode(config, CHAFA_PIXEL_MODE_SIXELS);
        break;
    case NONE:
      break;
    }
}

void draw_first_line(const char* title, const struct winsize *w, int endline) {
    size_t title_len = strlen(title);
    draw_string(UPPER_LEFT_CORNER);
    draw_horizontal_line();
    for (unsigned int n = 2; n < w->ws_col - 1; n += 1) {
        unsigned int current_char_index = n - 2;
        if (current_char_index < title_len) {
            draw_char(title[current_char_index]);
        } else {
            draw_horizontal_line();
        }
    }
    draw_string(UPPER_RIGHT_CORNER);
    if (endline) next_line(w->ws_row);
}

void draw_last_line(const struct winsize *w, int n, int outof) {
    // size_t title_len = strlen(title);
    int len = snprintf(NULL, 0, "%u/%u", n, outof);
    draw_string(LOWER_LEFT_CORNER);
    draw_horizontal_line();

    if (len > w->ws_col - 1) {
        for (unsigned int n = 2; n < w->ws_col - 1; n += 1) {
            draw_horizontal_line();
        }
    } else {
        for (unsigned int n = 2; n < w->ws_col - 1 - len; n += 1) {
            draw_horizontal_line();
        }
        fprintf(stdout, "%u/%u", n + 1, outof);
        fflush(stdout);
    }

    draw_string(LOWER_RIGTH_CORNER);
}

void draw_middle_line(const struct winsize *w, unsigned int row, int endline) {
    set_cursor_at(row, 0);
    draw_vertical_line();
    // move_forward_column(w->ws_col - 1);
    set_cursor_at(row, w->ws_col);
    draw_vertical_line();

    if (endline) next_line(row);
}

void draw_error_message(const struct winsize *w, const char* message) {
    size_t message_len = strlen(message);
    set_cursor_at(w->ws_row / 2 , (w->ws_col / 2) - (message_len / 2) );
    draw_string(message);
}

void draw_main_window(const char* title, int n, int outof) {
    struct winsize w;
    ioctl(0, TIOCGWINSZ, &w);
    size_t title_len = strlen(title);
    for (int nrow = 0; nrow < w.ws_row; nrow += 1) {
        if (nrow == 0 ) draw_first_line(title, &w, 1);
        else if (nrow == w.ws_row - 1) draw_last_line(&w, n, outof);
        else draw_middle_line(&w, nrow + 1, 1);
    }
}

void draw_image(const struct winsize *w, render_mode_t mode, size_t image_width,  size_t image_height, size_t row_stride, const unsigned char* pixels) {
    size_t scaled_width = w->ws_col * SCALE;
    size_t scaled_height = w->ws_row * SCALE;
    unsigned int start_point_draw_x = ((w->ws_col - scaled_width) / 2) + 1;
    unsigned int start_point_draw_y = ((w->ws_row - scaled_height) / 2) + 1;
    ChafaCanvasConfig* config = chafa_canvas_config_new();
    set_pixel_mode(config, mode);

    chafa_canvas_config_set_geometry(config, scaled_width, scaled_height);
    ChafaCanvas* canvas = chafa_canvas_new(config);
    chafa_canvas_draw_all_pixels (canvas,
                                  CHAFA_PIXEL_RGBA8_UNASSOCIATED,
                                  pixels,
                                  image_width,
                                  image_height,
                                  row_stride);

    GString* s = chafa_canvas_print(canvas, NULL);
    set_cursor_at(start_point_draw_y, start_point_draw_x);
    draw_gstring(s);

    g_string_free(s, TRUE);
    chafa_canvas_unref(canvas);
    chafa_canvas_config_unref(config);
}

MagickWand* create_wand_of_page(page_t page) {
    MagickWand* magick_wand = NewMagickWand();
    MagickBooleanType status = MagickReadImageBlob(magick_wand, page.ptr, page.len);
    if (status == MagickFalse) return NULL;
    return magick_wand;
}


void redraw_main_window(const char* title, int n, int outof, const struct winsize *w) {
    if (w) {
        redraw_empty(w);
    }
    set_cursor_at(0, 0);
    draw_main_window(title, n, outof);
}

exit_status_t draw_page_wand(const struct winsize* w, MagickWand* magick_wand, const page_t* image, const render_mode_t mode, const size_t current_image_index, const size_t nbimage) {
    if (!magick_wand) return MAGICKNULL;

    size_t image_width = MagickGetImageWidth(magick_wand);
    size_t image_height = MagickGetImageHeight(magick_wand);


    size_t row_stride =  image_width * NCHANNEL;
    const unsigned char *pixels = malloc( sizeof(unsigned char) * image_height * row_stride);
    if (!pixels) return MALLOC_FAIL;

    MagickStatusType status = MagickExportImagePixels(magick_wand, 0, 0, image_width, image_height, RGBA, CharPixel, (void *) pixels);
    if (status == MagickFalse) {
        free( (void *) pixels);
        return MAGICK_EXPORT_FAIl;
    }
    // clear();
    redraw_main_window("manga name", current_image_index, nbimage, NULL);
    draw_image(w, mode, image_width, image_height, row_stride, pixels);


    free( (void *) pixels);
    return NO_ERROR;
}


typedef enum {
    ERROR = -1,
    START,
    END,
    QUIT
} exit_side_t;



void show_page(const struct winsize ws, render_mode_t mode, const value *const page_array, const size_t len, ssize_t index) {
    CAMLparam0();
    CAMLlocal1(caml_current_page);
    caml_current_page = Field(page_array[index], 0);
    page_t c_page = {
        .ptr = (const uint8_t*) String_val(caml_current_page),
        .len = caml_string_length(caml_current_page)
    };

    MagickWand* wand_page = create_wand_of_page(c_page);
    if (!wand_page) return;

    exit_status_t status = draw_page_wand(&ws, wand_page, &c_page, mode, index, len);

    DestroyMagickWand(wand_page);
}

exit_side_t read_comic(render_mode_t mode, value archive_path) {
    CAMLparam1(archive_path);
    CAMLlocal4(caml_comic, caml_pages, caml_comic_name, head);
    caml_comic = caml_comic_of_zip(archive_path);
    caml_comic_name = Field(caml_comic, 0);
    caml_pages = Field(caml_comic, 1);
    
    const size_t nb_pages = caml_list_len(caml_pages);
    ssize_t index = 0;

    value *const page_array = malloc(nb_pages * sizeof(value));
    if (!page_array) return ERROR;


    while (caml_pages != Val_emptylist) {
        head = Field(caml_pages, 0);
        page_array[index] = head;
        caml_pages = Field(caml_pages, 1);
        index = index + 1;
    }

    int is_running = 1;
    index = 0;
    exit_side_t exit_side;
    char input_char;
    int refresh = 1;

    while (is_running) {
        struct winsize w;
        ioctl(0, TIOCGWINSZ, &w);
        if (index < 0) {
            is_running = 0;
            exit_side = START;
            break;
        } else if (index >= nb_pages) {
            is_running = 0;
            exit_side = END;
            break;
        }

        if (refresh) {
            show_page(w, mode, page_array, nb_pages, index);
        }

        int _ = read(STDIN_FILENO, &input_char, 1);
        switch (input_char) {
            case 'q': {
                is_running = 0;
                exit_side = QUIT;
                break;
            }
            case 'j': {
                index = (index - 1) % nb_pages;
                refresh = 1;
                break;
            }
            case 'l': {
                index = (index + 1) % nb_pages;
                refresh = 1;
                break;
            }
            default: {
                refresh = 0;
            }
                
        }

    }

    free((void *) page_array);
    return exit_side;
}


/// 
/// render_mode -> string list -> unit -> unit 
CAMLprim value caml_read_comics(value render, value comics, value unit) {
    CAMLparam3(render, comics, unit);
    render_mode_t mode = Int_val(render);
    size_t nb_comics = caml_list_len(comics);
    start_window();

    

    end_window();
    CAMLreturn(Val_unit);
}