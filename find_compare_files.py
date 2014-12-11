#!/usr/bin/env python
import os
import sys
from subprocess import Popen, PIPE

def merge_dicts(dict1, dict2):
    """
    For each key in dict2, add the values to the values for the key in dict1. If the
    key doesn't exist in dict1 it will be created.
    """
    for key in dict2:
        try:
            dict1[key].append(dict2[key])
        except KeyError:
            dict1[key] = dict2[key]

def walk_dir(dir_name, a_dict):
    """
    Examines every file in dir_name and its children. Adds to a_dict a key for each
    file hash computed, with the value being the list of every file name with that
    hash. Note that all files under a particular key will have identical contents.
    @param dir_name: A directory name, suitable for os.listdir()
    @type dir_name: string
    @param a_dict: map file hash => list of file names
    @type a_dict: mapping such as a dictionary.
    """
    l = os.listdir(dir_name)
    for fname in [os.path.join(dir_name, name) for name in l]:
        if os.path.isdir(fname):
            walk_dir(fname, a_dict)
        if os.path.isfile(fname):
            output = Popen(["md5sum", fname], stdout=PIPE).communicate()[0]
            d = output.split(' ')[0]

            try:
                a_dict[d].append(fname)
            except:
                a_dict[d] = [fname]

if __name__ == '__main__':
#if one directory, we should find files with same contents in that directory
#if two directories, we should files across directories (and within?)
    if len(sys.argv) < 2:
        print("give me a directory")
        sys.exit(1)
    sfiles = {}
    start = sys.argv[1]
    walk_dir(start, sfiles)
    print("{0} unique files found in {1}".format(len(sfiles), start))
#    s2files = {}
#    walk_dir(start2, s2files)
#    print("{0} unique files found in {1}".format(len(s2files), start2))
#    merge_dicts(sfiles, s2files)
    for key in sfiles:
        if len(sfiles[key]) > 1:
            print("Duplicates:")
            for f in sfiles[key]:
                print("   {0}".format(f))
