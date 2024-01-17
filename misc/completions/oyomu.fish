set -l commands add decrypt delete init list read rename

complete -c oyomu -n "__fish_use_subcommand" -l help -d 'Show help information'
complete -c oyomu -n "__fish_use_subcommand" -l version -d 'Show version information'
complete -c oyomu -n "__fish_use_subcommand" -f -a "collection" -d 'Manage oyomu collection'
complete -c oyomu -n "__fish_use_subcommand" -f -a "config" -d 'Configure oyomu'
complete -c oyomu -n "__fish_use_subcommand" -f -a "read" -d 'Read comics'

complete -c oyomu -n "__fish_seen_subcommand_from config" -f -s n -l new -d "Create the config if it doesn't exist"
complete -c oyomu -n "__fish_seen_subcommand_from config" -f -r -l keep-unzipped -d "Indicate whether unzipped comics should be kept in memory"
complete -c oyomu -n "__fish_seen_subcommand_from config" -f -r -l goto-book -d "Character that should be press if you want to go to a specific book"
complete -c oyomu -n "__fish_seen_subcommand_from config" -f -r -l goto-page -d "Character that should be press if you want to go to a specific page"
complete -c oyomu -n "__fish_seen_subcommand_from config" -f -r -l goto-page -d "Character that should be press if you want to go to a specific page"
complete -c oyomu -n "__fish_seen_subcommand_from config" -f -r -l next-page -d "Character that should be press if you want to go to the next page"
complete -c oyomu -n "__fish_seen_subcommand_from config" -f -r -l prev-page -d "Character that should be press if you want to go to the previous page"
complete -c oyomu -n "__fish_seen_subcommand_from config" -f -r -l quit -d "Character that should be press if you want to exit oyomu"
complete -c oyomu -n "__fish_seen_subcommand_from config" -f -r -l x-scale -d "X Scale" -a "sixels= kitty= iterm= symbols="

complete -c oyomu -n "__fish_seen_subcommand_from read" -f -r -s p -l pixel -a "symbols sixels kitty iterm" -d "Pixel mode used to render"
complete -c oyomu -n "__fish_seen_subcommand_from read" -f -l keep-unzipped -d "Indicate whether unzipped comics should be kept in memory"

complete -c oyomu -n "__fish_seen_subcommand_from collection;not __fish_seen_subcommand_from $commands" -l randomize-iv -d "Randomize the initialization vector of the encrypted comics"
complete -c oyomu -n "__fish_seen_subcommand_from collection" -f -a "add" -d "Add comics to the collection"
complete -c oyomu -n "__fish_seen_subcommand_from collection" -f -a "decrypt" -d "Decrypt encrypted comics"
complete -c oyomu -n "__fish_seen_subcommand_from collection" -f -a "delete" -d "Delete comics from collection"
complete -c oyomu -n "__fish_seen_subcommand_from collection" -f -a "init" -d "Initialise the comics collection"
complete -c oyomu -n "__fish_seen_subcommand_from collection" -f -a "list" -d "List series in collection"
complete -c oyomu -n "__fish_seen_subcommand_from collection" -f -a "read" -d "Read comics from collection"
complete -c oyomu -n "__fish_seen_subcommand_from collection" -f -a "rename" -d "Rename comics"

complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from add" -f -s e -l encryption -d "Add comic to yomu encrypted"
complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from add" -f -r -s i -l index -d "Volume starting index"
complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from add" -f -r -s n -l name -d "Name of the comic"
complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from add" -f -s x -l exist -d "Indicate that the comic should already exist"

complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from decrypt" -f -r -s a -l all -d "A separated list of all the comic where all the volumes should be selected"
complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from decrypt" -r -r -s d -l output-dir -d "Output directory of decrypted comics"
complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from decrypt" -f -s q -l quiet-dir -d "Don't echo comic name when successfully decrypted" 

complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from delete" -f -s e -l encrypt -d "Look also in the encrypted comics"
complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from delete" -f -r -s a -l all -d "A separated list of all the comic where all the volumes should be selected"

complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from init" -s e -l encryption -d "Init the encrypted part of oyomu"
complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from init" -s f -l force -d "Force the initialisation"

complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from list" -f -s e -l encrypt -d "List also the encrypted series"
complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from list" -f -s N -l name-only -d "Only display the serie's name"

complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from read" -f -r -s a -l all -d "A separated list of all the comic where all the volumes should be selected"
complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from read" -f -s e -l encrypt -d "Look also in the encrypted comics"
complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from read" -f -l keep-unzipped -d "Indicate whether unzipped comics should be kept in memory"
complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from read" -f -r -s p -l pixel -a "symbols sixels kitty iterm" -d "Pixel mode used to render"
complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from read" -f -s r -d "Treat comic name as a regex"

complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from rename" -f -s e -l encrypt -d "Rename encrypted comic serie"
complete -c oyomu -n "__fish_seen_subcommand_from collection; __fish_seen_subcommand_from rename" -f -s m -l merge -d " If the new comic name points to an existing serie, try to merge all the comics into that serie"


