(**********************************************************************************************)
(*                                                                                            *)
(* This file is part of Yomu: A comic reader                                                  *)
(* Copyright (C) 2023 Yves Ndiaye                                                             *)
(*                                                                                            *)
(* Yomu is free software: you can redistribute it and/or modify it under the terms            *)
(* of the GNU General Public License as published by the Free Software Foundation,            *)
(* either version 3 of the License, or (at your option) any later version.                    *)
(*                                                                                            *)
(* Yomu is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;          *)
(* without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR           *)
(* PURPOSE.  See the GNU General Public License for more details.                             *)
(* You should have received a copy of the GNU General Public License along with Yomu.         *)
(* If not, see <http://www.gnu.org/licenses/>.                                                *)
(*                                                                                            *)
(**********************************************************************************************)

(* open Cmdliner

   let name = "edit"

   type t = {
     next_page : char option;
     previous_page : char option;
     goto_page : char option;
     goto_book : char option;
   }

   let next_page_term =
     Arg.(
       value
         & opt (some char) None
         & info ["next-page"] ~doc:"Set the key to be used to go to the next page"
     )

   let previous_page_term =
     Arg.(
       value
         & opt (some char) None
         & info ["prev-page"] ~doc:"Set the key to be used to go to the previous page"
     )

   let goto_page_term =
     Arg.(
       value
         & opt (some char) None
         & info ["goto-page"] ~doc:"Set the key to be used to go to a specific page"
     )

   let goto_book_term =
     Arg.(
       value
         & opt (some char) None
         & info ["goto-book"] ~doc:"Set the key to be used to go to a specific book"
     )

   let cmd_term runner =
     let combine next_page previous_page goto_page goto_book =
       runner @@ {next_page; previous_page; goto_page; goto_book}
     in
     Term.(const combine
       $ next_page_term
       $ previous_page_term
       $ goto_page_term
       $ goto_book_term
     )


   let doc = "Configure $(mname)"
   let man =  [ `S Manpage.s_description; `P doc ]

   let cmd run =
     let info = Cmd.info name ~doc ~man in
     Cmd.v info (cmd_term run)

   let run cmd =
     let {next_page; previous_page; goto_book; goto_page } = cmd in
     let keyvals = Libyomu.Init.read_config () in

     ()

   let command = cmd run *)
