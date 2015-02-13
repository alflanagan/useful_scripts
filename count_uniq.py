#!/usr/bin/env python3
import sys
from collections import defaultdict


def count_uniq_lines(input_stream):
    d = defaultdict(int)  # default 0

    for line in input_stream:
        line = line[:-1]
        d[line] += 1

    sys.stderr.write("Lines in file: {:,}.\n".format(sum([d[k] for k in d])))

    k = [k for k in d]
    k.sort(key=str.lower)
    for b in k:
        print("{}:  {}".format(b, d[b]))

if __name__ == '__main__':
    if len(sys.argv) > 1:
        with open(sys.argv[1], "r") as txt_in:
            sys.stderr.write("Reading from {}.\n".format(sys.argv[1]))
            count_uniq_lines(txt_in)
    else:
        count_uniq_lines(sys.stdin)
