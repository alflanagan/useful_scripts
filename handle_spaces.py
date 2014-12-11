#!/usr/bin/env python
import sys
import os
import subprocess

if __name__ == '__main__':
    if len(sys.argv) < 3:
        my_name = os.path.basename(sys.argv[0])
        sys.stderr.write(
"""
Usage: {0} shell_cmd1 shell_cmd2
       Takes the output of shell_cmd2, encloses each line in quotes, and
       calls shell_cmd1 with the line as an argument. Works like shell syntax
          $ shell_cmd1 $(shell_cmd2)
       except that spaces in output of shell_cmd2 do not count as word breaks.
       Ex: the following will work on files/directories with spaces:
          $ {0} 'du -sh' 'ls'
""".format(my_name))
        sys.exit(1)

    program=sys.argv[1]
    input_source = sys.argv[2]
    p = subprocess.Popen(input_source, shell=True, stdout=subprocess.PIPE)
    for line in p.stdout:
        p2 = subprocess.Popen("{0} '{1}'".format(program, line.rstrip('\n\r')), shell=True, stdout=subprocess.PIPE)
        for line in p2.stdout:
            sys.stdout.write(line)
