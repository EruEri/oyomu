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

#include <string.h>
#define CAML_NAME_SPACE

#include "caml/config.h"
#include "caml/misc.h"
#include "caml/memory.h"
#include "caml/alloc.h"
#include "caml/mlvalues.h"
#include <unistd.h>


CAMLprim value caml_get_pass(value prompt, value unit) {
    CAMLparam2(prompt, unit);
    CAMLlocal1(password);
    const char* c_prompt = String_val(prompt);
    const char* c_password = getpass(c_prompt);
    size_t c_password_length = strlen(c_password);
    password = caml_copy_string(c_password);
    memset((void *) c_password, 0, c_password_length);
    CAMLreturn(password);
}