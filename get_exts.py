#!/usr/bin/env python
from __future__ import unicode_literals, print_function

import os
import sys
import codecs

def get_files(adir):
    files = []
    ldirs = os.listdir(adir)
    for ldir in ldirs:
        assert isinstance(adir, unicode)
        if not isinstance(ldir, unicode):
            try:
                #OK, have had some fun with weird file names
                #file names in Linux are utf-8, but some created from Windows are...
                ldir = codecs.decode(ldir, 'iso-8859-1')
            except:
                hstr = ""
                for ch in ldir:
                    hstr += hex(ord(ch))[2:]  # remove leading "0x"
                print("directory {0}".format(adir))
                print("ldir (hex) is {0}".format(hstr))
                print(codecs.decode(ldir, 'utf-8', 'replace'))
                print(codecs.decode(ldir, 'latin-1', 'replace'))
                sys.exit(1)
        assert isinstance(ldir, unicode)
        fpath = os.path.join(adir, ldir)
        assert isinstance(fpath, unicode)
        if os.path.isfile(fpath):
            files.append(ldir)
        elif os.path.isdir(fpath):
            files.extend(get_files(fpath))
    return files

#print(len(get_files('.')))
exts = [os.path.splitext(fname)[1] for fname in get_files('.')]
set_exts = set(exts)
#print(len(set_exts))
#print(set_exts)
for ext in set_exts:
    print(ext)
