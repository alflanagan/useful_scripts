#!/usr/bin/env python

import subprocess
import sys
import os
import fcntl
import threading
import time

def set_fd_non_blocking(fd):
    "Sets given file descriptor to non-blocking mode. Unix-only"
    fl = fcntl.fcntl(fd, fcntl.F_GETFL)
    fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)

def read_non_blocking_from(stream):
    "Loops to read data from stream."
    print("flags are {0}".format(fcntl.fcntl(stream.fileno(), fcntl.F_GETFL)))
    block = fcntl.fcntl(stream.fileno(), fcntl.F_GETFL) & os.O_NONBLOCK
    if block == os.O_NONBLOCK:
        print("stream is non-blocking.")
    else:
        print("stream is blocking!")
    while True:
        try:
            bytes_out = stream.readline()
            if bytes_out:
                print("read: " + bytes_out)
        except:
            continue

child = subprocess.Popen(['/usr/bin/ftp', '-n'], 
                         bufsize = 1,  #line buffered
                         stdin=subprocess.PIPE,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT)

#these work. ftp is not cooperating...
#child = subprocess.Popen(['echo', 'this is a test'], stdout=subprocess.PIPE) 
#child = subprocess.Popen(['cat', ], stdin=subprocess.PIPE, stdout=subprocess.PIPE) 

set_fd_non_blocking(child.stdout.fileno())

read_thread = threading.Thread(target=read_non_blocking_from, args=[child.stdout])
read_thread.daemon = True
read_thread.start()

print("started read thread.")

child.stdin.write('open 10.175.8.16\n')
child.stdin.flush()
print("opened target\n")
child.stdin.write('bye\n')
child.stdin.flush()
#print("bye")

time.sleep(5)
child.wait()
