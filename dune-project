(lang dune 3.2)

(name yomu)

(generate_opam_files true)

(source
 (github EruEri/yomu))

(authors "EruEri")

(maintainers "EruEri")

(license GPL-3.0)


(package
 (name yomu)
 (synopsis "A comic reader")
 (depends ocaml dune cmdliner xdg unix)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
