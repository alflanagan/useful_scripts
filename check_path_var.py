#!/usr/bin/env python

# It prints to stdout if a path is duplicated, or if a path is to a directory
# which does not exist

import sys
import os

if __name__ == '__main__':

    if len(sys.argv) != 2 or '-h' in sys.argv:
        print('Usage: check_path_var.py <path_name>', file=sys.stderr)
        sys.exit(1)

    pathname = sys.argv[1]
    pathvalue = os.environ.get(pathname, '').split(os.pathsep)

    errors = 0
    pathfound = []

    for path in pathvalue:
        if path == '':
            continue
        if path in pathfound:
            print(f'Found duplicate directory in {pathname}: {path}.', file=sys.stderr)
            errors += 1
        elif not os.path.exists(path):
            print(f'Directory in {pathname} does not exist: {path}.', file=sys.stderr)
            errors += 1
        else:
            pathfound.append(path)
    sys.exit(errors)
