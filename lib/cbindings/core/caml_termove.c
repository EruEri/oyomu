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

#include "caml_termove.h"
#include "caml/memory.h"
#include "caml/mlvalues.h"
#include "caml/memory.h"
#include "caml/misc.h"
#include "caml/callback.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>

const char* NEW_SCREEN_BUFF_SEQ = "\033[?1049h\033[H";
const char* END_SRCEEN_BUFF_SEQ = "\033[?1049l";
const char* CLEAR_CONSOLE = "\033[2J";
const char* UPPER_LEFT_CORNER = "┌";
const char* UPPER_RIGHT_CORNER = "┐";
const char* LOWER_LEFT_CORNER = "└";
const char* LOWER_RIGTH_CORNER = "┘";
const char* HORIZONTAL_LINE = "─"; // "─" != '-'
const char* VERTICAL_LINE = "│";


struct termios raw;
struct termios orig_termios;

void enableRawMode() {
    tcgetattr(STDIN_FILENO, &orig_termios);
    raw = orig_termios;
    raw.c_lflag &= ~(ECHO | ICANON);
    // raw.c_lflag &= ~(ICANON);
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
}

void disableCanonic() {
    raw.c_lflag &= ~(ICANON);
}

void enableCanonic() {
    raw.c_lflag |= ICANON;
}

void disableRawMode() {
  raw.c_lflag |= (ECHO | ICANON);  
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
}

void start_window() {
    enableRawMode();
    write(STDOUT_FILENO, NEW_SCREEN_BUFF_SEQ, strlen(NEW_SCREEN_BUFF_SEQ));
}

void end_window() {
    write(STDOUT_FILENO, END_SRCEEN_BUFF_SEQ, strlen(END_SRCEEN_BUFF_SEQ));
    disableRawMode();
}

CAMLprim value caml_enable_raw_mode(value unit) {
    CAMLparam1(unit);
    enableRawMode();
    CAMLreturn(unit);
}

CAMLprim value caml_disable_raw_mode(value unit) {
    CAMLparam1(unit);
    disableRawMode();
    CAMLreturn(unit);
}

CAMLprim value caml_enable_canonic(value unit) {
    CAMLparam1(unit);
    enableCanonic();
    CAMLreturn(unit);
}

CAMLprim value caml_disable_canonic(value unit) {
    CAMLparam1(unit);
    disableCanonic();
    CAMLreturn(unit);
}



void set_cursor_at(unsigned int line, unsigned int colmn) {
    fprintf(stdout, "\033[%u;%uf", line, colmn);
    fflush(stdout);
}

void move_down(unsigned int l) {
    fprintf(stdout, "\033[%uB", l);
    fflush(stdout);
}

void clear(){
    fprintf(stdout, "%s", CLEAR_CONSOLE);
    fflush(stdout);
}

void move_forward_column(unsigned int c) {
    fprintf(stdout, "\033[%uC", c);
    fflush(stdout);
}


void draw_vertical_line() {
    fprintf(stdout, "%s", VERTICAL_LINE);
    fflush(stdout);
}

void draw_gstring(GString* gstring){
    fwrite (gstring->str, sizeof (char), gstring->len, stdout);
    fflush(stdout);
}

void draw_horizontal_line() {
    fprintf(stdout, "%s", HORIZONTAL_LINE);
    fflush(stdout);
}

void draw_string(const char* s) {
    fprintf(stdout, "%s", s);
    fflush(stdout);
}

void draw_char(char c) {
    fprintf(stdout, "%c", c);
    fflush(stdout);
}

void next_line(unsigned int current_line) {
    set_cursor_at(current_line + 1, 0);
    fflush(stdout);
}

void redraw_empty(const struct winsize* w){
    set_cursor_at(0, 0);
    for (unsigned int i = 0; i < w->ws_col * w->ws_row; i += 1) {
        draw_char(' ');
    } 
}