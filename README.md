# Useful Scripts

This is just a grab-bag of a bunch of scripts of I wrote over time for
various purposes. In some cases, the term "useful" is probably an
exaggeration.

## LICENSE

These programs are free software: you can redistribute them and/or modify them
under the terms of the GNU Affero General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your option)
any later version.

These programs are distributed in the hope that they will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along
with these programs. If not, see <https://www.gnu.org/licenses/>.

## Some of the Files Included

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
    
* __file_dupes.py__

  Searches a file directory tree for files that are duplicates
  (contents are identical). Checks file sizes first, if it finds
  two or more files with the same size it runs `md5sum` to get
  a checksum and checks whether the results are identical.

* __dopercent.bash__

  `dopercent.bash NN command...`
  
  Randomly executes a command, with probability NN percent. Useful
  for spot checks, simulations, etc.

* __report_class_hier.py__

  Handy script to scan one or more Python source files and report
  classes that are defined in them, with the parent-child 
  relationships displayed with indenting.
