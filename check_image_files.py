#!/usr/bin/env python3.4
# vim:ts=4:sw=4:expandtab:fileencoding=utf-8 -*- coding:utf-8; -*-
# note python3.4 needed to get html.unescape() function
"""Script to verify that image files referenced in the NITF files in a
given directory actually exist in that directory.

"""
import os
import tempfile
import sys
import re
import subprocess
import html

IMG_REF_RE = r'<media-reference[^>]+source="([^"]*)".*?/>'
IMG_REF = re.compile(IMG_REF_RE)


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


def usage():
    """Display usage message and exit."""
    sys.stderr.write("""Usage: {0} directory [--missing [--quiet]]
     Reports the number of images referenced by NITF files in the directory, and
     how many of those files are actually present.
     If --missing is present, prints list of image files not found.
     If --quiet is added, ONLY prints file names.
""".format(os.path.basename(sys.argv[0])))
    sys.exit(1)


def check_files_in_dir(dir_to_check, print_missing, print_totals):
    files = set(os.listdir(dir_to_check))

    img_refs = set()

    if print_totals:
        print("grepping XML files...")

    # it turns out that grep is WAY faster than iterating lines in a file and using re module
    matched_lines = grep_files('<media-reference', '*.xml', dir_to_check)
    for line in matched_lines:
        assert isinstance(line, str)
        # unfortunately, we don't have each <media-reference tag on separate line
        # make list from callable
        matches = list(IMG_REF.finditer(line))
        for media_ref_match in matches:
            if not media_ref_match.groups()[0].endswith('.flv'):
                ifilename = html.unescape(media_ref_match.group(1))
                img_refs.add(ifilename)
    #    if not matches:
    #        print("No match: '{0}'".format(line))

    missing = img_refs - files

    if missing:
        if print_totals:
            print("Found {} image file references, but {} {} missing!"
                  "".format(len(img_refs), len(missing), "are" if len(missing) > 1 else "is"))
        if print_missing:
            for fname in missing:
                print(fname)
        sys.exit(2)
    else:
        if print_totals:
            print("All {} image files accounted for.".format(len(img_refs)))


def check_all():
    """Main procedure: process command line, grep NITF files, report results."""
    # defaults
    print_missing = False
    print_totals = True

    argset = set(sys.argv[1:])

    if '--missing' in argset:
        print_missing = True
        argset -= set(['--missing'])

    if '--quiet' in argset:
        if print_missing:
            print_totals = False
        else:
            err_msg("Ignoring --quiet parameter; only meaningful if --missing also given.")
        argset -= set(['--quiet'])

    if len(argset) < 1:
        usage()

    dir_to_check = argset.pop()

    if len(argset):
        err_msg("Unrecognized arguments!")
        usage()

    if not os.path.exists(dir_to_check):
        err_msg("Directory {} does not exist!".format(dir_to_check))
        usage()

    check_files_in_dir(dir_to_check, print_missing, print_totals)


if __name__ == '__main__':
    check_all()
