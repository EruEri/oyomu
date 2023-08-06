(lang dune 3.2)
(version "0.2.0")

(name oyomu)

(generate_opam_files true)

(source
 (github EruEri/oyomu))

(authors "EruEri")

(maintainers "EruEri")

(license GPL-3.0)


(package
 (name oyomu)
 (synopsis "A command line comic reader and collection manager")
 (depends (ocaml (>= "4.13.0")) (camlzip (>= "1.11")) dune-build-info dune (cmdliner (>= "1.1.0")) xdg unix)
 (tags
  ( "comics-reader" "comics-collection" "commandline")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
