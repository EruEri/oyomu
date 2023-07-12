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


#include "callback.h"
#include "caml/mlvalues.h"
#include "caml/callback.h"
#include "caml/memory.h"
#include <stddef.h>

#define c_comic_of_zip "c_comic_of_zip"
#define c_list_len "c_list_len"

caml_comic_t caml_comic_of_zip(value path) {
    CAMLparam1(path);
    static const value* closure = NULL;
    if (!closure) closure = caml_named_value(c_comic_of_zip);
    return caml_callback(*closure, path);
}


size_t caml_list_len(value list) {
    CAMLparam1(list);
    CAMLlocal1(len);
    static const value* closure = NULL;
    if (!closure) closure = caml_named_value(c_list_len);
    len = caml_callback(*closure, list);
    return Long_val(len);
}