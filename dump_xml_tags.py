#!/usr/bin/env python3
"""Script to print out tags found in an XML file in a nested format."""
import os
import sys

from lxml import etree as ET


def print_tags(a_node, indent, use_graphic):
    # unicode drawing chars
    bottom_left_corner = chr(0x2515)
    horiz_line = chr(0x2500)
    graphic = bottom_left_corner + horiz_line * 3

    instr = '    ' * (indent)
    if use_graphic:
        print('{}{}{}'.format(instr, graphic, a_node.tag))
    else:
        print('{}{}'.format(instr, a_node.tag))

    for kid in a_node.getchildren():
        if kid.tag != ET.Comment:
            print_tags(kid, indent + 1, use_graphic)


def show_usage():
    sys.stderr.write("""Usage: {} [--graphic] xml_file
       Prints XML tags found in xml_file, with nesting indicated by indent.
       If --graphic is present, uses drawing chars; otherwise just spaces.\n\n"""
                     "".format(os.path.basename(sys.argv[0])))
    sys.exit(1)


def main():
    fname = sys.argv[1]
    graphics = False
    if fname == "--graphic":
        graphics = True
        fname = sys.argv[2]
    elif len(sys.argv) == 3:
        if sys.argv[2] == "--graphic":
            graphics = True
        else:
            show_usage()

    print_tags(ET.parse(fname).getroot(), 0, graphics)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        show_usage()
    else:
        main()
