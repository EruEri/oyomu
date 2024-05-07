(lang dune 3.2)
(version "0.3.0-1")

(name oyomu)

(generate_opam_files true)

(source
 (github EruEri/oyomu))

(authors "EruEri")

(maintainers "EruEri")

(license GPL-3.0-or-later)


(package
 (name oyomu)
 (synopsis "A command line comic reader and collection manager")
 (depends dune dune-configurator dune-build-info xdg (ocaml (>= "4.14.0")) (cryptokit (>= "1.17")) (camlzip (>= "1.11")) (ppx_deriving_yojson (>= "3.5.3")) (yojson (>= "2.0.0"))  (cmdliner (>= "1.1.0")))
 (tags
  ( "comics-reader" "comics-collection" "commandline")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
