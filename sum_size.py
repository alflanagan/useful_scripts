#!/usr/bin/env python3
"""
Given a list of file nums, sum the sizes of the files, print result.

"""

import sys
import os

total = 0

if len(sys.argv) < 2:
    sys.stderr.write('Usage: {0} file_list\n'.format(os.path.basename(sys.argv[0])))
    sys.stderr.write('       Sums the file sizes of files in file_list, prints result.\n')

for file_arg in sys.argv[1:]:
    if not os.path.exists(file_arg):
        sys.stderr.write("File {0} not found!\n".format(file_arg))
    elif not os.path.isfile(file_arg):
        sys.stderr.write("{0} is not a file, skipping\n".format(file_arg))
    else:
        st = os.stat(file_arg)
        total += st.st_size

print(total)
if total > 1024:
    print("{0:2,.3f} KB".format(total / 1024))
if total > 1024 * 1024:
    print("{0:2,.3f} MB".format(total / (1024 * 1024)))
