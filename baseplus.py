#!/usr/bin/env python3
# -*- coding:utf-8 -*-
from pathlib import Path
import sys

for fname in sys.argv[1:]:
    print(Path(fname).name)
