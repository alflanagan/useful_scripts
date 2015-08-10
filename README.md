# Useful Scripts

This is just a grab-bag of a bunch of scripts of I wrote over time for
various purposes. In some cases, the term "useful" is probably an
exaggeration.

* __functions.bash__

  A set of bash functions for various things. Notable ones include

  * `bldpath`: adds a directory to a path-type variable (PATH,
    MANPATH, LD\_LIBRARY\_PATH, etc.) only if that directory is not
    already present.

    Various functions build on `bldpath` to provide useful
    operations for common path variables.

  * `every`: executes a command every X seconds

  * `with`: execute a command in a different directory, restore
    current directory after

  * `which`: extends the which command to find and print functions,
    aliases

  * `sum_size`: print just the sum of the sizes of the files given

  * `comp`: do completion expansion for a command, as though hitting
    `tab` on the command line -- useful for scripts
    
