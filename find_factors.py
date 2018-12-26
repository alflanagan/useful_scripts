#!/usr/bin/env python3
import math
import sys

def factors(n):
    for a in range(2, int(math.sqrt(n))+1):
        if n % a == 0:
            print("{:,} -- {:,}".format(a, n // a))

if __name__ == '__main__':
    if len(sys.argv) > 1:
        factors(int(sys.argv[1]))
