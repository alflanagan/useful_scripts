#!/usr/bin/env python3
import sys
from collections import defaultdict


def count_uniq_lines(input_stream):
    d = defaultdict(int)  # default 0

    for line in sys.stdin:
        line = line[:-1]
        d[line] = d[line] + 1

    sum = 0
    for l in d.keys():
        sum = sum + d[l]
        print("Total # of lines is {}.".format(sum([v for k, v in d])))

    k = d.keys()
    k.sort()
    for b in k:
        print("{}:  {}".format(b, d[b]))

if __name__ == '__main__':
    if len(sys.argv) > 1:
        with open(sys.argv[1], "r") as txt_in:
            print("Reading from {}.".format(sys.argv[1]))
            count_uniq_lines(txt_in)
    else:
        count_uniq_lines(sys.stdin)
