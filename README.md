# Oyomu

Oyomu is a simple comic reader that allows you to read comic in your terminal.

Your terminal should at least support one of this format for the page to be somewhat readable:
- Sixels
- Iterm
- Kitty

## How to use

### Read

To read comics, use the ```read``` subcommand

Use the "j" for left and the "l" for right and 'q' for quit
```
$ oyomu read --help
NAME
       oyomu-read - Read comics

SYNOPSIS
       oyomu read [--pixel=PIXEL_MODE] [OPTION]… <FILES.(cbz|zip)>…

DESCRIPTION
       Read commic

ARGUMENTS
       <FILES.(cbz|zip)> (required)
           Archive of the comic. The archives must be zip archive

OPTIONS
       -p PIXEL_MODE, --pixel=PIXEL_MODE (absent=symbols)
           pixel mode to use to render the imagesone of 'symbols', 'sixels',
           'kitty' or 'iterm'
```

- MacOS:
    - Iterm2:
        - [Sixel](/img/macos_iterm_sixel.png)
        - [Iterm](/img/macos_iterm_iterm.png)
- FreeBSD:
    - WezTerm
        - []
        - []



### Future

Other features will be added but read is the minimun for a comic reader

## How to build
- First you will need to install those opam packages.
    ```sh
    $ opam install dune xdg camlzip cmdliner dune-configurator
    ```

- You will also need to install those C libraries:
  - [Chafa](https://github.com/hpjansson/chafa)
    - Chafa >= 1.12.4
  - [ImageMagick](https://github.com/imagemagick/imagemagick)
    - ImageMagick >= 7.0.0
    
  The C libraries must be found by **pkg-config**

- And finally:
  ```sh
  git clone https://github.com/EruEri/oyomu
  cd oyomu
  dune build
  ```