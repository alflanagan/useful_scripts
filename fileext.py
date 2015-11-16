#!/usr/bin/env python3
import os
import sys

for argv in sys.argv[1:]:
    print(os.path.splitext(argv)[1])
