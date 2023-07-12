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


#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#define CAML_NAME_SPACE

#include "caml/mlvalues.h"
#include "caml/memory.h"
#include "caml/misc.h"
#include "caml/callback.h"
#include "comic.h"


#define c_comic_of_zip "c_comic_of_zip"

caml_comic_t caml_comic_of_zip(value path) {
    CAMLparam1(path);
    static const value* closure = NULL;
    if (!closure) closure = caml_named_value(c_comic_of_zip);
    return caml_callback(*closure, path);
}


page_t page_of_caml_page(value page) {
    CAMLparam1(page);
    CAMLlocal1(data);
    data = Field(page, 0);
    const uint8_t* bytes = (const uint8_t*) String_val(data);
    size_t len = caml_string_length(data);
    page_t c_page = {.ptr = bytes, len = len};
    return c_page;
}


caml_comic_t comic_of_path_archive(value path) {
    CAMLparam1(path);
    CAMLlocal1(caml_comic);
    caml_comic = caml_comic_of_zip(path);
    return caml_comic_of_zip(caml_comic);
}
