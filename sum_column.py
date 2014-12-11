#!/usr/bin/env python
"""Short script to add up a column of numbers -- from stderr or file named on command line."""
from __future__ import print_function

import sys

# pylint: disable=C0103

if len(sys.argv) > 1:
    in_stream = open(sys.argv[1], 'r')
else:
    in_stream = sys.stdin

counter = 0
for line in in_stream:
    counter += int(line[:-1])

print(counter)

if len(sys.argv) > 1:
    in_stream.close()

