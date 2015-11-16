#!/usr/bin/env python3

import sys
import os


def usage():
    sys.stderr.write("Usage: {} FILE [FILE...]\n".format(os.path.basename(sys.argv[0])))
    sys.stderr.write("       Reads each FILE as windows cp1252 encoding and writes it")
    sys.stderr.write("       as utrf-8 encoded to file file FILE.utf8.")
    sys.exit(1)


def main(args):
    for fname in args:
        with open(fname, 'r',
                  encoding='cp1252') as winin, open(fname + '.utf8', 'w',
                                                    encoding='utf-8') as utfout:
            for line in winin:
                utfout.write('{}\n'.format(line[:-1]))


if __name__ == '__main__':
    if len(sys.argv) < 2:
        usage()
    else:
        main(sys.argv[1:])
