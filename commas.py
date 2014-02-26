#!/usr/bin/env python

from __future__ import print_function

import os, sys


def split_preserve_ws(a_string):
    result = []
    mylen = len(a_string)
    split_index = 0
    #get all the non-whitespace
    #TODO: Try version with re and find(), test which is faster
    while split_index < mylen and a_string[split_index] not in (' ', '\t'):
        split_index +=1
    result.append(a_string[:split_index])
    word_end = split_index
    #then get all the following whitespace
    while split_index < mylen and a_string[split_index] in (' ', '\t'):
        split_index +=1
    result.append(a_string[word_end:split_index])
    #call ourselves on rest of string
    #TODO: replace with loop
    if split_index < mylen:
        result.extend(split_preserve_ws(a_string[split_index:]))
    return result


def add_commas(anumber):
    l = len(anumber)
    if anumber.isdigit() and l > 3:
        return add_commas(anumber[:-3]) + "," + anumber[-3:]
    else:
        return anumber

for line in sys.stdin:
    #something like this should work in 2.7 and above
    #print("{0:,}".format(line))
    #parts = line[:-1].split(" ") # TODO: this will remove spaces, which we really shouldn't
    parts = split_preserve_ws(line[:-1])
    #print(parts)
    newlist = []
    for part in parts:
        newlist.append(add_commas(part))
    print(" ".join(newlist))
