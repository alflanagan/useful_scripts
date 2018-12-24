#!/usr/bin/env python3
"""A script to find duplication of file contents in a directory tree."""
import os
import argparse
from subprocess import Popen, PIPE
from collections import defaultdict


class DirType(object):
    """Factory for creating directory object types for `argparse`.

    Instances of DirType are typically passed as type= arguments to the
    ArgumentParser add_argument() method. This guarantees that the argument,
    if present, is a valid directory.

    """
    def __call__(self, pathlike):
        if os.path.isdir(pathlike):
            os.listdir(pathlike)  # verify readability
            return pathlike
        else:
            raise ArgumentTypeError('{} is not a directory'.format(pathlike))

def get_args():
    """Process command-line options, return options object."""
    desc = "Calculate a hash for each file in a directory tree, report duplicates."
    parser = argparse.ArgumentParser(description=desc)

    parser.add_argument('directory', help="The name of a directory to scan")
    parser.add_argument('--max-files', type=int, default=100, metavar='COUNT',
                        help="A maximum number of files to scan. 0 ==> no maximum.")
    parser.add_argument('--relative_to', type=DirType(), default='/',
                        metavar='DIR_NAME',
                        help="Top-level directory for stored filenames")
    parser.add_argument('--store',
                        type=argparse.FileType('w'),
                        help="Filename of a a persistent storage file. Files from previous run will not be re-scanned or count against '--max-files' limit, but will be reported.")
    return parser.parse_args()

def merge_dicts(dict1, dict2):
    """
    Merge `dict1` and `dict2`.

    If a key is found in both dicts, the list of values
    in `dict2` will be appended to the list in `dict1`.
    """
    for key in dict2:
        dict1[key].append(dict2[key])

def walk_dir(dir_name, a_dict, max_files):
    """
    Walks the directory tree under `dir_name`, getting a hash value for each file.

    Adds hashes to `a_dict`, a dictionary whose keys are hash values, and whose
    values are lists of file names who hash to that value.

    @param dir_name: A directory name, suitable for os.listdir()
    @type dir_name: string
    @param a_dict: map file hash => list of file names
    @type a_dict: mapping such as a dictionary.
    @param max_files: The maximum # of files to scan (0 -> no maximum).
    @type max_files: int

    @return {int} Number of files found.
    """
    files_found = 0
    filelist = os.listdir(dir_name)
    for fname in [os.path.join(dir_name, name) for name in filelist]:
        if os.path.isdir(fname):
            files_found += walk_dir(fname, a_dict, max_files - files_found)
        if os.path.isfile(fname):
            # do some voodoo here to make path name relative to argument
            # do some more voodoo to determine if we have file's data already
            # set of filenames (and dates and sizes?)
            output = Popen(["md5sum", fname], stdout=PIPE).communicate()[0]
            md5_key = output.split(b' ')[0]

            a_dict[md5_key].append(fname)
            files_found += 1
        if max_files > 0 and files_found >= max_files:
            return files_found
    return files_found

def main(args):
    """Set up the duplicate file search, report results."""
    sfiles = defaultdict(list)
    if args.store is not None:
        print("Here we need to read the existing store, if any.")
    walk_dir(args.directory, sfiles, args.max_files)
    if args.store is not None:
        print("Here we need to write the persistent storage.")
    print("{0} unique files found in {1}".format(len(sfiles), args.directory))
    for key in sfiles:
        if len(sfiles[key]) > 1:
            print("Duplicates:")
            for fpath in sfiles[key]:
                print("   {0}".format(fpath))


if __name__ == '__main__':
    main(get_args())
