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


#include "MagickCore/magick-type.h"
#include "MagickWand/MagickWand.h"
#include "caml/memory.h"
#include "caml/alloc.h"
#include "caml/misc.h"
#include "caml/mlvalues.h"
#include <stddef.h>
#define CAML_NAME_SPACE

value Val_MagickWand(MagickWand* ptr) {
    value v = caml_alloc(1, Abstract_tag);
    *((MagickWand **) Data_abstract_val(v)) = ptr;
    return v;
}

MagickWand* MagickWand_val(value caml_magick) {
    return *((MagickWand **) Data_abstract_val(caml_magick));
}

CAMLprim value caml_magick_wand_genesis(value unit) {
    CAMLparam1(unit);
    MagickWandGenesis();
    CAMLreturn(unit);
}


CAMLprim value caml_magick_wand_terminus(value unit) {
    CAMLparam1(unit);
    MagickWandTerminus();
    CAMLreturn(unit);
}


CAMLprim value caml_new_magick_wand(value unit) {
    CAMLparam1(unit);
    MagickWand* magick = NewMagickWand();
    CAMLreturn(Val_MagickWand(magick));
}

CAMLprim value caml_destroy_magick_wand(value wand) {
    CAMLparam1(wand);
    MagickWand* magick = MagickWand_val(wand);
    DestroyMagickWand(magick);
    CAMLreturn(Val_unit);
}

CAMLprim value caml_magick_read_image_blob(value wand, value string_blob) {
    MagickWand* magick = MagickWand_val(wand);
    const char* content = String_val(string_blob);
    size_t len = caml_string_length(string_blob);
    MagickBooleanType status = MagickReadImageBlob(magick, content, len);
    return (status == MagickTrue) ? Val_true : Val_true;
}