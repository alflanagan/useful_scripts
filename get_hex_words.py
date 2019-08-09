#!/usr/bin/env python3
import sys
import json

DIGITS = {'O': '0', 'L': 'l', 'S': '5',    # RE -faster?
          'A': 'A', 'B': 'B', 'C': 'C', 'D': 'D', 'E': 'E', 'F': 'F'}


def convertible(some_word):
    for char in some_word:
        if char not in  DIGITS:
            return False
    return True

def to_hex(some_word):
    as_hex = ""
    for char in some_word:
        as_hex += DIGITS[char]
    return as_hex

def check(some_word):
    if convertible(some_word):
        print(some_word)
    else:
        print('Sorry!')


def main():
    try:
        with open('common_word_list.json', 'r') as wordin:
            word_dict = json.load(wordin)
    except IOError:
        import os
        mydir = os.path.dirname(sys.argv[0])
        with open(os.path.join(mydir, 'common_word_list.json'), 'r') as wordin:
            word_dict = json.load(wordin)

    min_length = 4
    if len(sys.argv) > 1:
        min_length = int(sys.argv[1])

    print("Searching {:,} common English words".format(len(word_dict)))

    counter = 40
    for word in word_dict:
        if len(word) < min_length:
            continue
        uword = word.upper()
        if convertible(uword):
            print("{} => {}".format(word, to_hex(uword)))
            counter -= 1
            if counter <= 0:
                break

if __name__ == '__main__':
    main()
