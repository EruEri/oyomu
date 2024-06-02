# Suyomu

**suyumu** is a suwayomi command line frontend.

Your terminal should at least support one of this format for the page to be somewhat readable:
- Sixels
- Iterm
- Kitty

### How to use

#### Start
```
NAME
       suyomu - a suwayomi frontend

SYNOPSIS
       suyomu [COMMAND] …

DESCRIPTION
       suyomu allows to interact with a suwayomi backend

       If no subcommand if provided, suyomu start the tui.
       In order to fetch data from the suwayomi backend, suyomu must have the
       required options. Those options can be set with suyomu-config(1)
       ,overrided with the (b,-c) option which take a configuration file like
       suyomu-config(1) would create or given as argument

COMMANDS
       config [OPTION]…
           Configure suyomu

       install-apk [OPTION]… [APKS]…
           install apks to suwayomi

OPTIONS
       -c <CONFIG_FILE>, --config=<CONFIG_FILE>
           Overrides the default configuration

       --host=<HOST>
           Overrides the hostname of the server

       --https=<false | true>
           Overrides the https protocol

       -p <PIXEL_MODE>, --pixel=<PIXEL_MODE> (absent=symbols)
           pixel mode to use to render the images. one of 'symbols',
           'sixels', 'kitty' or 'iterm'

       --port=<PORT>
           Overrides the port of the server

       --username=<USERNAME>
           Overrides the username to use if a basic access authentication is
           required
```

### Config

The `config` subcommand configures the necessary options to connect to the suwayomi 
backend.

```
NAME
       suyomu-config - Configure suyomu

SYNOPSIS
       suyomu config [OPTION]…

DESCRIPTION
       The configuration file is located in your
       XDG_CONFIG_HOME/yomu/suyomurc.

       This file is a json file where the expected keys are: port, host,
       https, username, password.

       Extra keys are ignored.

OPTIONS
       --host=<HOST>
           Indicate the hostname of the server

       --https=<true | false>
           Indicate whether the protocol to connect to the backend should be
           https

       -n  Create the config if it doesn't exist

       --password
           Indicate the username to use if a basic access authentication is
           required. The password is read with getpass(3)

       --port=<PORT>
           Indicate the port to connect to the backend

       --username=<USERNAME>
           Indicate the username to use if a basic access authentication is
           required
```


### Installation
- First you will need to install those opam packages.
    ```sh
    $ opam install dune xdg camlzip cmdliner dune-configurator cryptokit yojson ppx_deriving_yojson ocurl base64
    ```

- You will also need to install those C libraries:
  - [Chafa](https://github.com/hpjansson/chafa)
    - Chafa >= 1.12.4
  - [ImageMagick](https://github.com/imagemagick/imagemagick)
    - ImageMagick >= 7.0.0
    
  The C libraries must be found by **pkg-config**

By default the prefix install is `/usr/local`. So suyomu binary is installed in `/usr/local/bin` and the man pages in `/usr/local/share/man`. 
But the `make install` rule reacts to 3 variables:
- `PREFIX`: 
  - default: `/usr/local`
- `BINDIR`: 
    - default: `$(PREFIX)/bin`
- `MANDIR`: 
    - default: `$(PREFIX)/share/man`

```sh
$ git clone https://codeberg.org/EruEri/oyomu
$ cd oyomu
$ make suyomu 
$ make install-suyomu
```
