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

#define CAML_NAME_SPACE

#ifndef _COMIC_H
#define _COMIC_H

#include <caml/mlvalues.h>
#include <stddef.h>
#include <stdint.h>

typedef value caml_comic_t;

typedef struct {
    const uint8_t* ptr;
    const size_t len;
} page_t;

typedef struct {
    const char* name;
    page_t* p_pages;
} comic_t;

caml_comic_t comic_of_path_archive(value path);


#endif