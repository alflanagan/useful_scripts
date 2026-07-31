<style>
body {
  max-width: 768px;
  margin: 0 auto;
}
</style>

# Shell Functions (zsh)

## From functions.zsh

These are functions found in the `functions.zsh` file, which is sort of a
grab-bag of various useful `zsh` functions. I use functions for code that needs
to execute in the user's process, or for short commands a little too involved
for using `alias`.

Note that for `zsh`, you could put each function in its own file in an
autoloaded directory. This single file is sort of a relic, a holdover from my
`bash` days. One day I may get around to redoing it.

Also I use the [Oh My Zsh](https://ohmyz.sh/) framework, which adds lots of nice
goodies to `zsh`, and has its own setup for custom functions.

### Functions testing or changing PATH-style variables

These functions are for use in checking or modifying any environment variable
which is a series of directory names separated by `:`. The best-known of these
is the `PATH` variable, but there are several others that are widely used, such
as `MANPATH` and `LD_LIBRARY_PATH`.

**bldpath** is a helper function for the other **pathmunge**-type functions. It
  does the actual work of adding a directory to a path variable, and is used by
  the other functions to add to specific variables like `MANPATH` and
  `LD_LIBRARY_PATH`. The other functions also provide usage messages.

**pathmunge** is function that adds a directory to the existing `PATH`
  environment variable. It will not add a directory if it is already in the
  variable. A second argument of `before` adds the path to the front; otherwise,
  it adds the path to the end of the variable.

An error will be displayed if the directory does not exist. The command cache is
reset after, so that the shell will look for existing commands in the new
directory.

**is_in_path** returns 0 (true) if the argument is a directory in the `PATH`
  variable, and 1 (false) if it is not present.

**pathrm** takes the name of a directory. If the directory is in the `PATH`
  variable, it is removed. It is not an error if the path is not in the
  variable, the function will leave `PATH` unchanged.

**manmunge**: like `pathmunge` but it changes the `MANPATH` variable.

**ldlibmunge**: like `pathmunge` but it changes the `LD_LIBRARY_PATH` variable.

**functions**: list all `zsh` functions defined in the current environment.

**fixldpath**: rebuilds `LD_LIBRARY_PATH` without duplicate entries.

### Process and file-listing helpers

**myps**: lists the current user's processes after filtering common system and
  background processes.

**findtextin**: searches files matching a name pattern below a starting
  directory for a supplied text string.

**ll**, **lrt**, **lrtail**, and **lrtc**: provide long-format directory
  listings, respectively unsorted, sorted by time, limited to the final lines,
  or passed through `commall.py`.

**largest**: lists files sorted by size. **llgv**: lists files that do not match
  a supplied pattern, using `lgv`.

### Functions for executing commands

**every**: a function that allows commands like "every 3 do ls", which runs the
  command `ls` every 3 seconds until ctrl-C is pressed. There is a very similar
  command called `watch`, but it's not available in all environments (such as
  MacOS).

**with**: executes a command with the working directory set somewhere else, such
  as "with ~/bin do cat functions.zsh". It restores the current working
  directory on exit.

### File Sizes

**sum_size**: sums the sizes of the list of files passed to it. **NOTE:** `du`
  is not reliable on MacOS, need to fix this.

### Numeric Conversions

**h2d**: converts a hex number to the equivalent decimal: `h2d abcd` ==>
  "43981". **x2d** is a shortcut for it.

**h2b**: converts a hex number to the equivalent binary: "h2b ab" ==>
  "10101011".

**o2d**: converts an octal (base 8) number to the equivalent decimal:
  "o2d 72417" ==> "29967". Checks that input is a valid octal number.

**d2h**: converts a decimal integer to hex format: "d2h 43981" ==> "ABCD".

**d2o**: converts a decimal integer to octal (base 8): "d2o 29967" ==> "72417".

### `curl` Shortcuts

**curl_get**: Retrieves a URL using curl and saves it to a file, or prints an
  error message.

**curl_get_missing**: like `curl_get`, but does not retrieve the file if the
  filename already exists.

### Better Names for Obscure Expressions

**endswith**: returns success when its first argument ends with its second
  argument. The suffix is matched literally, so special pattern characters in
  it have no special meaning.

**dbshell**: semi-intelligent shortcut for `python manage.py dbshell` (part of
  the [Django](https://djangoproject.com) framework.

**truepath**: returns the absolute path of file, recursing through symlinks as
  needed.

**columns**: prints stdin in the number of columns given as an argument.

**zip_list**: lists the file names stored in a ZIP archive.

**dtree**: lists directory names using `tree`.

**view_html**: opens an HTML file in Firefox, converting spaces in its path to
  URL escapes.

**cs**: runs Django's `collectstatic --noinput`.

**npm_packages**: lists the top-level npm packages without their versions.

### Project

My half-baked `project` command, which allows you to say `"project fred"` and
automatically switch to the root directory for fred, and set up any environment
needed for the type of project. It relies on the convention that the top-most
(root) directory for the project is the name of the project.

NOTE: Uses a list of directories in the variable `GIT_PARENTS`, which you will
need to customize.

**project**: the master command. Given the base name of a project directory,
  locates that project and sets up the environment as needed. Also accepts
  `completion` as an argument, which returns a list of all projects found, and
  should be set up as completion values for `zsh` as soon as I get around to it.

**get_project_names_from_git**: given a directory, list all its descendants with
  a .git subdirectory.

**\_project\_complete**: emits project names from each directory in
  `GIT\_PARENTS`, one name per line, for `project completion`.

**find_git_project**: given 2 arguments, the root of a directory tree and the
  name of a project, search for a directory with the same name as the project
  which has a subdirectory named `.git`. NOTE: May not return the expected
  result if 2 directories with the project name exist in the tree.

**find_all_git_project**: applies `find_git_project` to each directory in
  `GIT_PARENTS` and returns the path of the project when found.

### Others

**with_commas**: given an integer argument, returns the argument formatted with
  commas as the thousands separator: "with_commas 12345678" ==> "12,345,678".
  Intended for use in various shell scripts to improve readability.

**kts**: shortcut to execute a Kotlin file as a script.

**mkcd**: creates a directory path when necessary, then changes into it.

**maketasks**: lists all targets in the `Makefile` in the current directory.

**vmd**: runs `vmd` with Node's stable version in a subshell. **startblack**:
  starts `blackd`, then displays its log. **print\_virtenv**: prints the active
  Python virtual environment's name when one is set.

On non-Debian systems, **xwhich** extends `which` to show aliases and functions.

### Emacs

Commands to start emacs in various ways.

**e**: opens the given file in emacs, using an emacs server if one is running.
  It discovers the server socket through a batch Emacs invocation and writes to
  `emacs.log` or `emacsclient.log` in the configured log directory.


**em**: start a logged emacs process, don't use emacsclient even if a server is
  running.

**emdebug**: starts emacs with `--debug-init` and logging, for debugging startup
  problems.

**prelude**: starts emacs with the `prelude` configuration directory, not the
  default one.

### Fussy checks

**check_path_variables**: scans through a number of environment variables
  formatted as a list of directories with ':' as a separator. Reports when a
  directory does not exist, or when it duplicates an earlier path. Handy for
  cleanup of variable configurations.

<!--
LocalWords:  zsh MANPATH LD
 -->
