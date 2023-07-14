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

#ifndef TERMOVE_H
#define TERMOVE_H

#include "caml/misc.h"
#include "caml/mlvalues.h"
#include <chafa.h>
#include <termios.h>
#include <sys/ioctl.h>

extern const char* NEW_SCREEN_BUFF_SEQ;
extern const char* END_SRCEEN_BUFF_SEQ;
extern const char* CLEAR_CONSOLE;
extern const char* UPPER_LEFT_CORNER;
extern const char* UPPER_RIGHT_CORNER;
extern const char* LOWER_LEFT_CORNER;
extern const char* LOWER_RIGTH_CORNER;
extern const char* HORIZONTAL_LINE; // "─" != '-'
extern const char* VERTICAL_LINE;

void enableRawMode();
void disableRawMode();
void end_window();
void start_window();

CAMLprim value caml_enable_raw_mode(value unit);

CAMLprim value caml_disable_raw_mode(value unit);

void set_cursor_at(unsigned int line, unsigned int colmn);

void move_down(unsigned int l);

void clear();

void move_forward_column(unsigned int c);

void draw_vertical_line();

void draw_gstring(GString* gstring);

void draw_horizontal_line();

void draw_string(const char* s);

void draw_char(char c);

void next_line(unsigned int current_line);

void redraw_empty(const struct winsize* w);



#endif