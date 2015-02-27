#!/usr/bin/env python3
"""Program to list absolutely all objects in a git repository, including unreachable ones."""
import subprocess
import sys


def check_output_list(*args):
    """Acts like :py:meth:`subprocess.check_output`, but returns the
    output as a list of unicode strings.

    Arguments are identical to those for `check_output`.

    """
    raw_output = subprocess.check_output(*args)
    raw_output = raw_output.decode(sys.getdefaultencoding())
    return raw_output.split("\n")


def format_git_hash(int_hash):
    """Returns `int_hash`, which must be an integer, as a 40-digit hex
    string, with leading zeroes if needed.

    """
    return hex(int_hash)[2:].rjust(40, "0")


def git_object_type(int_hash):
    """Returns the type of object denoted by `int_hash`."""
    return subprocess.check_output("git cat-file -t {}".format(
        format_git_hash(int_hash)).split(" ")).decode(sys.getdefaultencoding()).replace("\n", "")


def git_object_size(int_hash):
    """Returns the size of the object denoted by `int_hash`, in bytes."""
    return int(subprocess.check_output("git cat-file -s {}".format(
        format_git_hash(int_hash)).split(" ")).decode(sys.getdefaultencoding()).replace("\n", ""))


def main():
    object_list = check_output_list(["git", "rev-list", "--objects", "--all"])
    print("Found {:,} objects in object_list.".format(len(object_list)))
    from_ref_logs = check_output_list("git rev-list --objects -g --no-walk --all".split(" "))
    print("Found {:,} objects from rev-list -g".format(len(from_ref_logs)))

    unreachable_objects = [line for line in
                           check_output_list(
                               "git fsck --unreachable --strict --no-progress".split(" "))
                           if len(line) > 0]
    print("Found {:,} unreachable objects.".format(len(unreachable_objects)))
    hashes = {}
    for line in object_list:
        parts = line.split(" ")
        if len(parts) == 2:
            hashes[parts[1]] = int(parts[0], 16)  # hashes[file_name] = git hash
    print("Found {:,} objects with file names.".format(len(hashes)))

    # hashes.update([int(h, 16) for h in from_ref_logs])
    # print("Found {:,} unique object ids.".format(len(hashes)))

    for fname in hashes:
        otype = git_object_type(hashes[fname])
        if otype != "tree":
            print("{}: {}".format(fname, git_object_size(hashes[fname])))

    # cat_file = subprocess.check_output(["git", "cat-file",
    #                                     "blob", format_git_hash(hashes[fname])])

#     git rev-list --objects --no-walk \
#         $(git fsck --unreachable |
#           grep '^unreachable commit' |
#           cut -d' ' -f3)
#     git fsck --unreachable | grep "^unreachable blob" | cut -d' ' -f3
# } 2> /dev/null | cut -d' ' -f1 | sort | uniq); do
#     if git cat-file blob $hash 2> /dev/null | grep -i $content > /dev/null ; then
#         echo $hash
#     fi

if __name__ == "__main__":
    main()
