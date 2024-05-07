# Oyomu

Oyomu is a command line comic collection manager and also a comic reader

Your terminal should at least support one of this format for the page to be somewhat readable:
- Sixels
- Iterm
- Kitty

Currently only the zip archive are handle properly

## How to use

### Read

To read comics, use the ```read``` subcommand

By default, it uses the "h" for left and the "l" for right and 'q' for quit
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
           pixel mode to use to render the images one of 'symbols', 'sixels',
           'kitty' or 'iterm'
```

[Demonstration: MacOS iTerm](https://imgur.com/a/7pRl4j1)

### Collection

The ```collection``` subcommand allows you to handle your collection

````
$ oyomu collection --help
NAME
       oyomu-collection - Manage Oyomu collection

SYNOPSIS
       oyomu collection COMMAND …

DESCRIPTION
       oyomu collection allows you to manager and read your comic collection

COMMANDS
       add [OPTION]… <FILES.(cbz|zip)>…
           Add comics to the collection

       delete [--all=COMIC] [--encrypt] [OPTION]… [<VOL.COMIC>]…
           Delete comics from collection

       init [--encryption] [--force] [OPTION]…
           Initialise the comics collection

       list [--encrypt] [--name-only] [OPTION]… [SERIE]…
           List series in collection

       read [--all=COMIC] [--encrypt] [--pixel=PIXEL_MODE] [OPTION]…
       [<VOL.COMIC>]…
           Read comics from collection
````

#### Init

To Initialize the collection use ```ìnit``` subcommand

Oyomu has 2 strategies to store your comic:
- Normal:
    - Your comics are stored in your **$XDG_DATA_HOME/yomu/comics** directory where each folder holds the volumes of the serie
- Encrypted:
    - Your comics are stored in your **$XDG_DATA_HOME/yomu/.scomics** directory and are encrypted with a password that the ```ìnit``` 
    wizard will ask you to set if the option **--encryption** is set


#### Add / Delete / List

- Those subcommands do are respectively add, delete and list comics

#### Read
- You can also read comics within your collection with the ```read``` subcommand of ```oyomu collection```

## Installation
- First you will need to install those opam packages.
    ```sh
    $ opam install dune xdg camlzip cmdliner dune-configurator cryptokit yojson ppx_deriving_yojson
    ```

- You will also need to install those C libraries:
  - [Chafa](https://github.com/hpjansson/chafa)
    - Chafa >= 1.12.4
  - [ImageMagick](https://github.com/imagemagick/imagemagick)
    - ImageMagick >= 7.0.0
    
  The C libraries must be found by **pkg-config**

By default the prefix install is `/usr/local`. So oangou binary is installed in `/usr/local/bin` and the man pages in `/usr/local/share/man`. 
But the `make install` rule reacts to 3 variables:
- `PREFIX`: 
  - default: `/usr/local`
- `BINDIR`: 
    - default: `$(PREFIX)/bin`
- `MANDIR`: 
    - default: `$(PREFIX)/share/man`

```sh
$ git clone https://github.com/EruEri/oangou
$ cd oangou
$ make 
$ make install 
```