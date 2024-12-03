# CHANGELOG

## [0.5.0]:
**BREAKING CHANGES**
- Change oyomu xgd directory name:
    - yomu -> oyomu:
        - eg. ~/.local/share/**yomu**/ --> ~/.local/share/**oyomu**/
- Change option:
    - oyomu decrypt: 
        - \-a : separeted list -> repeted option
    - oyomu delete:
        - \-a : separeted list -> repeted option
    - oyomu read:
        - \-a : separeted list -> repeted option
- Change syomurc format:
    - Add a field to the encrypted json

**Features**
- Add epub support

**Miscellaneous**
- Replace libraries:
    - cryptokit -> digestif + mirage-crypto
    - str -> re-ocaml
- Code refacto:
    - Remove suyomu: (create its own repository)
    - Rename some functions from `yomu_` to `oyomu_`


## [0.4.0-1]
- Don't create temporaries files when unzipping files (load faster)
- [oyomu-rename]: Don't try to remove folder after rename (folder doesnt exist because rename (ie. mv) delete a old one)
- [oyomu-*-read]: Sort files by name before reading

## [0.4.0]
- [oyomu: change exits code](https://codeberg.org/EruEri/oyomu/pulls/16)
- [suyomu: suwayomu frontend](https://codeberg.org/EruEri/oyomu/pulls/15)

## [0.3.1]
- [Divers improvements](https://github.com/EruEri/oyomu/pull/13)

## [0.3.0-1]
- [Opam dependencies](https://github.com/EruEri/oyomu/pull/12)

## [0.3.0]
- [Collection read regex name](https://github.com/EruEri/oyomu/pull/10)
- [Improve Kitty, iTerm render](https://github.com/EruEri/oyomu/pull/9)

## [0.2.2-1]
- [Re-encrypt file with the new iv](https://github.com/EruEri/oyomu/pull/8)

## [0.2.2]
## Dont' use, randomize-iv is broken
- [Randomize Iv in encrypted comics](https://github.com/EruEri/oyomu/pull/7)
    - add option to create new random iv in ```oyomu collection``` (--randomize-iv)
    - generate a random seed when calling the random iv function

## [0.2.1]
- [Use config file to change some behavior](https://github.com/EruEri/oyomu/pull/5)

## [0.2.0]
- [Decrypt/Rename collection subcommand](https://github.com/EruEri/oyomu/pull/3)
- [Add option to read commands for unzip keep strategy](https://github.com/EruEri/oyomu/pull/2)
- [Use environment variable to change keybinding ](https://github.com/EruEri/oyomu/pull/1)

## [0.1.0]
- Inilial release