#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Checks files for the presence of non-ASCII printable characters.


| © 2015 BH Media Group, Inc.
| BH Media Group Digital Development

.. codeauthor:: A. Lloyd Flanagan <aflanagan@bhmginc.com>


"""
import sys
import re

BAD_CHARS_RE = None


def make_regex():
    """Build a compiled regex in BAD_CHARS_RE to recognize non-ASCII chars."""
    global BAD_CHARS_RE
    good_chars = ""
    for i in range(127 - 31):
        good_chars += chr(i + 32)

    BAD_CHARS_RE = re.compile(r"[^" + good_chars + "\n]")


def check_files(files):
    """Check each file in `files` for non-ASCII chars, return a list of those files."""
    bad_files = []
    for fname in files:
        with open(fname, 'r') as filein:
            contents = filein.read()
            match = BAD_CHARS_RE.search(contents)
            if match:
                bad_files.append(fname)
    return bad_files


if __name__ == '__main__':
    # TODO: check args, print usage, handle dirs, etc., etc.
    make_regex()
    found = check_files(sys.argv[1:])
    print("Found {:,} files with non-ASCII characters.".format(len(found)))
