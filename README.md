# Oyomu

The source code is now hosted on [Codeberg](https://codeberg.org/EruEri/oyomu)

**oyomu** is a command line comic collection manager and also a comic reader.

**suyomu** is a suwayomi command line frontend. 

Your terminal should at least support one of this format for the page to be somewhat readable:
- Sixels
- Iterm
- Kitty

Currently only the zip archive are handle properly

## Information

For more information about **oyomu** see the [README.oyomu.md](README.oyomu.md) file.

For more information about **suyomu** see the [README.suyomu.md](README.suyomu.md) file


## Dependencies



### oyomu

First you will need to install those opam packages.
 ```sh
    $ opam install dune xdg camlzip cmdliner dune-configurator cryptokit yojson ppx_deriving_yojson
```

### Suyomu

First you will need to install those opam packages.
 ```sh
    $ opam install dune xdg camlzip cmdliner dune-configurator cryptokit yojson ppx_deriving_yojson ocurl base64
```

For **oyomu** and **suyomu**, you will also need to install those C libraries:
  - [Chafa](https://github.com/hpjansson/chafa)
    - Chafa >= 1.12.4
  - [ImageMagick](https://github.com/imagemagick/imagemagick)
    - ImageMagick >= 7.0.0
    
The C libraries must be found by **pkg-config**
