#!/usr/bin/env python
#$Id$
#$URL$

#find sparse files, files that report a larger size than is actually stored
#on disk.
#ls -ls:
#total 4249446
#      2 -rw-r--r--+ 1 flanaganl eng         1011 Nov  9 12:35 TypeInfo.cpp
#      2 -rw-r--r--+ 1 flanaganl eng          786 Oct  2  2009 c++0xthings.cpp
#4249326 -rw-------+ 1 flanaganl eng 344029454336 Apr  6 14:28 core.31047

"""Script to find sparse-stored files in ext2/3/4 filesystems"""
from __future__ import print_function, unicode_literals  # This script requires Python 2.6 or later!

import os
import sys

SPINNER = r"-\|/"  # ASCII chars to create on-screen "spinner" display
BS = chr(8)  # backspace character


def check_dir(directory_name):
    "Check a given directory for sparse files."
    for fname in os.listdir(directory_name):
        filename = os.path.join(directory_name, fname)
        if os.path.isfile(filename):
            sresult = os.stat(filename)
            true_size = sresult.st_blocks * 1024
            if true_size < sresult.st_size:
                print(BS + "file {0} reports size {1}, but is really {2}"
                        "".format(filename, sresult.st_size, true_size))


def recurse_check_dir(top_dir, spindex):
    "Check a directory and all its subdirectories, recursively."
    check_dir(top_dir)
    files = [os.path.join(top_dir, fn) for fn in os.listdir(top_dir)]
    for afile in files:
        sys.stdout.write(BS + SPINNER[spindex])
        sys.stdout.flush()
        spindex = (spindex + 1) % len(SPINNER)
        if os.path.isdir(afile):
            recurse_check_dir(afile, spindex)


if __name__ == "__main__":
    START_DIR = '.'
    if len(sys.argv) > 1:
        START_DIR = sys.argv[1]
    recurse_check_dir(START_DIR, 0)
    print(BS)
