#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
from pathlib import Path
from collections import defaultdict
from subprocess import Popen, PIPE


def files_in_dir_tree(dirname):
    """Search directory `dirname` for files, recursing through
    subdirectories.

    :returns: An iterable of tuples of (filename, size) where size is
        the size of the file in bytes.

    """
    for fname in Path(dirname).glob('*'):
        if fname.is_file():
            yield (fname, fname.stat().st_size)
        elif fname.is_dir():
            yield from files_in_dir_tree(fname)


def find_files(filelist):
    """Given `filelist` as a list of file names and/or directories, create
    a list of all (regular) files within the directories
    (recursively).

    """
    for fname in [Path(name) for name in filelist]:
        if not fname.exists():
            raise FileNotFoundError(str(fname))
        if fname.is_file():
            yield (fname, fname.stat().st_size)
        elif fname.is_dir():
            yield from files_in_dir_tree(fname)


def check_for_dups(filelist):
    """Generates MD5 checksums for each file in a list, then returns a
    list of lists of files which are identical.

    Note: it is a good idea to check the file sizes first, as 2 files
    of different size will never be identical, and the check is _much_
    faster.

    """
    sums = defaultdict(list)
    for fname in filelist:
        output = Popen(["md5sum", str(fname)], stdout=PIPE).communicate()[0]
        checksum = output.split(b' ')[0]
        sums[checksum].append(fname)
    return [sums[checksum] for checksum in sums if len(sums[checksum]) > 1]


if __name__ == '__main__':
    sizes = defaultdict(list)
    for fname, fsize in find_files(sys.argv):
        sizes[fsize].append(fname)
    alldupes = []
    for key in [key for key in sizes if len(sizes[key]) > 1]:
        alldupes += check_for_dups(sizes[key])
    print("Found {:,} duplicate files.".format(
          sum([len(dupelist) for dupelist in alldupes])))
    for dupelist in alldupes:
        print('--------------------------')
        for fname in dupelist:
            print('    ' + str(fname))

# Local Variables:
# python-indent-offset: 4
# indent-tabs-mode: nil
# End:
