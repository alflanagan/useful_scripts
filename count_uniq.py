#!/usr/bin/env python2

import sys

d = {}
for line in sys.stdin.readlines():
    line = line[:-1]
    try:
        d[line] = d[line] + 1
    except KeyError:
        d[line] = 1

#print "Found %d distinct lines." % len(d.keys())

sum = 0
for l in d.keys():
    sum = sum + d[l]
print "Total # of lines is %d" % sum

#for b in [x for x in d.keys() if d[x] > 500]:
k = d.keys()
k.sort()
for b in k:
    print "%s:  %d" % (b, d[b])
