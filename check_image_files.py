#!/usr/bin/env python3
# vim:ts=4:sw=4:expandtab:fileencoding=utf-8 -*- coding:utf-8; -*-
# needs version 3.4 or later
"""Script to verify that image files referenced in the NITF files in a
given directory actually exist in that directory.

"""
import os
import tempfile
import sys
import re
import subprocess
import html
import argparse

IMG_REF_RE = r'<media-reference[^>]+source="([^"]*)".*?/>'
IMG_REF = re.compile(IMG_REF_RE)


def get_args():
    """Process command-line options, return options object."""
    desc = """
Match NITF files in a directory with image files by references in <media> tags.

Reports images referenced but not present, and present but not referenced."""

    parser = argparse.ArgumentParser(description=desc)

    parser.add_argument('directory', help="The name of a directory to scan")
    parser.add_argument('--quiet', action="store_true", help="Report *only* file names")
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--missing', action="store_true", help="List names of missing images")
    group.add_argument('--extra', action="store_true", help="List names of images not referenced")
    return parser.parse_args()


def err_msg(mesg):
    """Write an error message to stderr, in standard format."""
    msg = "{}: {}\n".format(os.path.basename(sys.argv[0]), mesg)
    sys.stderr.write(msg)


def grep_files(pattern, filespec, directory="."):
    """
    Searches for pattern in all files in directory that match filespec.

    Parameters:
    pattern: a search pattern in grep(1) format
    filespec: a file glob as specified by current shell
    directory: a directory name

    Returns:
    List of all lines containing pattern
    """
    results = []
    if directory != ".":
        pwd = os.path.abspath(os.curdir)
        os.chdir(directory)
    with tempfile.TemporaryFile() as tmpfil:
        # need shell since filespec should be globbed
        try:
            # This command a) handles spaces in file names, and b) handles long argument lists
            grep_cmd = ("find . -maxdepth 1 -name '{}' -print0 | xargs --null grep '{}'"
                        "".format(filespec, pattern))
            # print("executing {}".format(grep_cmd))

            # xargs exits with non-zero if any command invocation
            # returned non-zero, but grep returns 1 if it doesn't find
            # a matching line (although not an error in this
            # case). So, can't use subprocess.check_call().  We
            # probably should fail any time grep returns 2 or find
            # exits with non-zero, but would need a shell function and
            # possibly voodoo to do that. (or separate calls of find
            # and grep, which would affect performance at least).

            subprocess.call(grep_cmd, stdout=tmpfil, shell=True)
        except subprocess.CalledProcessError:
            # not sure we can get here; see previous comment
            err_msg("find + xargs failed; attempting to use plain grep.")
            try:
                grep_cmd = "grep '{0}' {1}".format(pattern, filespec)
                subprocess.check_call(grep_cmd, stdout=tmpfil, shell=True)
            except subprocess.CalledProcessError:
                err_msg("WARNING: grep command failed! Wrong directory? No image references?")
        tmpfil.seek(0)  # reset to read lines back
        for line in tmpfil:
            line = line.decode(sys.getdefaultencoding())
            results.append(line[:-1])
    if directory != ".":
        os.chdir(pwd)
    # print("grep returned {0} results".format(len(results)))
    return results


def test_grep_files():
    """Some rudimentary testing of grep_files function."""
    print(grep_files('media ', '*.xml'))
    print('----------------------')
    print(grep_files('[^"]*.jpg', '*.xml'))
    sys.exit(1)


def check_files_in_dir(dir_to_check, print_missing, print_extra, be_quiet):
    """Scans files in dir_to_check, prints output.

    Prints counts of missing and extra images, unless be_quiet == True

    Prints list of missing files, if print_missing == True

    Prints list of extra (unreferenced) files, if print_extra == True

    """
    files = set([fname for fname in os.listdir(dir_to_check) if not fname.endswith('.xml')])

    img_refs = set()

    if not be_quiet:
        print("grepping XML files...")

    # it turns out that grep is WAY faster than iterating lines in a file and using re module
    matched_lines = grep_files('<media-reference', '*.xml', dir_to_check)
    for line in matched_lines:
        assert isinstance(line, str)
        # unfortunately, we don't have each <media-reference> tag on separate line
        matches = IMG_REF.findall(line)
        for media_ref_match in matches:
            # if not media_ref_match.endswith('.flv'):
            ifilename = html.unescape(media_ref_match)
            img_refs.add(ifilename)

    missing = img_refs - files

    if missing:
        if not be_quiet:
            print("Found {:,} image file references, but {:,} {} missing!"
                  "".format(len(img_refs), len(missing), "are" if len(missing) > 1 else "is"))
        if print_missing:
            for fname in missing:
                print(fname)
    else:
        if not be_quiet:
            print("All {} image files accounted for.".format(len(img_refs)))

    extras = files - img_refs

    if extras:
        if not be_quiet:
            if len(extras) == 1:
                print("Found 1 non-XML file that is not referenced in NITF files.")
            else:
                print("Found {:,} non-XML files that are not referenced in NITF files."
                      "".format(len(extras)))
        if print_extra:
            for fname in extras:
                print(fname)
    elif not be_quiet:
        print("There are no non-XML files which are not referenced in the NITF files.")


def check_all(args):
    """Main procedure: process command line, grep NITF files, report results."""
    # defaults

    if args.quiet and not (args.missing or args.extra):
        err_msg("Ignoring --quiet parameter; only meaningful with --extra or --missing.")
        args.quiet = False

    if not os.path.exists(args.directory):
        err_msg("Directory {} does not exist!".format(args.directory))
        sys.exit(2)

    check_files_in_dir(args.directory, args.missing, args.extra, args.quiet)


if __name__ == '__main__':
    check_all(get_args())
