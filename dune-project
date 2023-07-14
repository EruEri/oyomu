(lang dune 3.2)
(version "0.0.1")

(name oyomu)

(generate_opam_files true)

(source
 (github EruEri/oyomu))

(authors "EruEri")

(maintainers "EruEri")

(license GPL-3.0)


(package
 (name oyomu)
 (synopsis "A comic reader")
 (depends (ocaml (>= "4.13.0")) (camlzip (>= "1.11")) dune-build-info dune (cmdliner (>= "1.1.0")) xdg unix)
 (tags
  ( "comic" "reader")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
