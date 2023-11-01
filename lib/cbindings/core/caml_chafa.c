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

#include <chafa.h>
#include <stdio.h>
#include "caml/memory.h"
#include "caml/misc.h"
#include "caml/mlvalues.h"
#include "caml/alloc.h"

extern int printf(const char*, ...);

value Val_ChafaCanvasConfig(ChafaCanvasConfig* ptr) {
    value v = caml_alloc(1, Abstract_tag);
    *((ChafaCanvasConfig **) Data_abstract_val(v)) = ptr;
    return v;
}

value Val_ChafaCanvas(ChafaCanvas* c) {
    value v = caml_alloc(1, Abstract_tag);
    *((ChafaCanvas **) Data_abstract_val(v)) = c;
    return v;
}

ChafaCanvas* ChafaCanvas_val(value caml_chafa_canvas) {
    return *((ChafaCanvas **) Data_abstract_val(caml_chafa_canvas));
}


ChafaCanvasConfig* ChafaCanvasConfig_val(value caml_chafa_config) {
    return *((ChafaCanvasConfig **) Data_abstract_val(caml_chafa_config));
}


CAMLprim value caml_chafa_canvas_config_new(value unit) {
    CAMLparam1(unit);
    CAMLlocal1(config_local);
    ChafaCanvasConfig* config = chafa_canvas_config_new();
    config_local = Val_ChafaCanvasConfig(config);
    CAMLreturn(config_local);
}

CAMLprim value caml_chafa_canvas_config_set_pixel_mode(value config, value pixel_mode) {
    CAMLparam2(config, pixel_mode);
    ChafaCanvasConfig* cconfig = ChafaCanvasConfig_val(config);
    ChafaPixelMode cmode = Int_val(pixel_mode);
    chafa_canvas_config_set_pixel_mode(cconfig, cmode);
    CAMLreturn(Val_unit); 
}

CAMLprim value caml_chafa_canvas_config_set_geometry(value config, value width, value height) {
    CAMLparam3(config, width, height);
    ChafaCanvasConfig* cconfig = ChafaCanvasConfig_val(config);
    // chafa_canvas_config_set_canvas_mode(cconfig, CHAFA_CANVAS_MODE_TRUECOLOR);
    int cwidth = Int_val(width);
    int cheight = Int_val(height);
    chafa_canvas_config_set_geometry(cconfig, cwidth, cheight);
    CAMLreturn(Val_unit);
}

CAMLprim value caml_chafa_calc_canvas_geometry(
        value caml_width, value caml_height, value caml_zoom,
        value caml_stretch, value caml_font_ration
    ) {
        CAMLparam5(caml_width, caml_height, caml_zoom, caml_stretch, caml_font_ration);
        CAMLlocal3(tuple, caml_calc_w, caml_calc_h);
        tuple = caml_alloc_tuple(2);
        int width = Int_val(caml_width);
        int height = Int_val(caml_height);
        gboolean zoom = Bool_val(caml_zoom);
        gboolean stretch = Bool_val(caml_stretch);
        double ration = Double_val(caml_font_ration);
        int calc_width = width;
        int calc_height = height;
        chafa_calc_canvas_geometry(width, height,&calc_width, &calc_height, ration, zoom, stretch);
        caml_calc_w = Val_int(calc_width);
        caml_calc_h = Val_int(calc_height);
        Store_field(tuple, 0, caml_calc_w);
        Store_field(tuple, 1, caml_calc_h);
        CAMLreturn(tuple);
    }

CAMLprim value caml_chafa_canvas_config_set_cell_geometry(value config, value width, value height) {
    CAMLparam3(config, width, height);
    ChafaCanvasConfig* cconfig = ChafaCanvasConfig_val(config);
    chafa_canvas_config_set_canvas_mode(cconfig, CHAFA_CANVAS_MODE_TRUECOLOR);
    int cwidth = Int_val(width);
    int cheight = Int_val(height);
    // chafa_calc_canvas_geometry(cwidth, cheight, &dest_width_inout, &dest_height_inout, 0.5, 1, 1);
    chafa_canvas_config_set_cell_geometry(cconfig, cwidth, cheight);
    CAMLreturn(Val_unit);
}

CAMLprim value caml_chafa_canvas_new(value config_opt, value unit) {
    CAMLparam2(config_opt, unit);
    CAMLlocal2(ret, some);
    ChafaCanvasConfig* config = NULL;
    if (Is_some(config_opt)) {
        some = Some_val(config_opt);
        config = ChafaCanvasConfig_val(some);
    }
    ChafaCanvas* ccanvas = chafa_canvas_new(config);
    ret = Val_ChafaCanvas(ccanvas);
    CAMLreturn(ret);
}

CAMLprim value caml_chafa_canvas_draw_all_pixels(
    value canvas, value pixel_type, value pixels,
    value width, value height, value row_stride 
) {
    CAMLparam5(canvas, pixel_type, pixels, width, height);
    CAMLxparam1(row_stride);
    ChafaCanvas* c_canvas = ChafaCanvas_val(canvas);
    ChafaPixelType c_pixel_type = Int_val(pixel_type);
    const unsigned char* c_pixels = Bytes_val(pixels);
    int c_width = Int_val(width);
    int c_height = Int_val(height);
    int c_row_stride = Int_val(row_stride);
    chafa_canvas_draw_all_pixels (c_canvas,
                                c_pixel_type,
                                c_pixels,
                                c_width,
                                c_height,
                                c_row_stride);

    CAMLreturn(Val_unit);
        
}

CAMLprim value caml_chafa_canvas_draw_all_pixels_bytecode(value* values, int argn) {
    return caml_chafa_canvas_draw_all_pixels(
        values[0], values[1], values[2], 
        values[3], values[4], values[5]
    );
}

CAMLprim value caml_chafa_canvas_print(value term_info, value canvas) {
    CAMLparam2(term_info, canvas);
    CAMLlocal1(caml_string);

    ChafaTermInfo* info = NULL;
    if (Is_some(term_info)) {
        // info = ChafaCanvasConfig_val(Some_val(term_info));
    }
    // Currently ignore term_info
    ChafaCanvas* c_canvas = ChafaCanvas_val(canvas);
    GString* str = chafa_canvas_print(c_canvas, info);
    caml_string = caml_alloc_string(str->len);
    char* c_caml_string = (char*) String_val(caml_string);
    memcpy(c_caml_string, str->str, str->len);
    g_string_free(str, TRUE);
    CAMLreturn(caml_string);
}

CAMLprim value caml_chafa_canvas_unref(value canvas) {
    CAMLparam1(canvas);
    ChafaCanvas* c_canvas = ChafaCanvas_val(canvas);
    chafa_canvas_unref(c_canvas);
    CAMLreturn(Val_unit);
}

CAMLprim value caml_chafa_canvas_config_unref(value config) {
    CAMLparam1(config);
    ChafaCanvasConfig* c_config = ChafaCanvasConfig_val(config);
    chafa_canvas_config_unref(c_config);
    CAMLreturn(Val_unit);
}