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

#include "caml_winsize.h"
#include "caml/memory.h"
#include "caml/alloc.h"
#include "caml/mlvalues.h"
#include <sys/ttycom.h>
#include <sys/ioctl.h>
#include <termios.h>

CAMLprim value caml_winsize(value unit) {
    CAMLparam1(unit);
    CAMLlocal1(block);
    struct winsize ws;
    ioctl(0, TIOCGWINSZ, &ws);
    block = caml_alloc_tuple(4);
    Store_field(block, 0, Val_int(ws.ws_row));
    Store_field(block, 1, Val_int(ws.ws_col));
    Store_field(block, 2, Val_int(ws.ws_xpixel));
    Store_field(block, 3, Val_int(ws.ws_ypixel));
    CAMLreturn(block);
}