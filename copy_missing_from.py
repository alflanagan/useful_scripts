#!/usr/bin/env python3
"""Utility script to copy files from one directory heirarchy to another."""

import argparse
from pathlib import Path


def check_args() -> argparse.Namespace:
    """Checks command-line arguments, returns a Namespace with values."""
    parser = argparse.ArgumentParser(
        description=(
            "Copy files from SOURCE_DIR to DEST_DIR if DEST_DIR does not have a file of "
            "that name already."
        )
    )
    parser.add_argument("source_dir", help="Directory from which to copy files.")
    parser.add_argument("dest_dir", help="Directory to which to copy files")
    parser.add_argument(
        "-r",
        "--recursive",
        action="store_true",
        help=(
            "Recurse into subdirectories, creating subdirs as needed in "
            "destination dir."
        ),
    )
    return parser.parse_args()


def fix_path(apath: Path, root_path: Path) -> str:
    """Return that part of APATH which is not part of ROOT_PATH, encoded as utf-8."""
    path_str = str(apath.absolute())
    root_str = str(root_path.absolute())

    if path_str == root_str:
        raise ValueError("Can't copy a path onto itself!!")

    if not path_str.startswith(root_str):
        raise RuntimeError(
            "Program error -- '{}' is not a descendant of '{}'".format(
                path_str, root_str
            )
        )

    return path_str[len(root_str) + 1:]


def get_files(apath: Path, root_dir: Path, adict: dict, recurse: bool):
    """Add files from APATH as values in ADICT, with key being the 'fixed path' of APATH."""
    for entry in apath.iterdir():
        isinstance(entry, Path)
        if entry.is_file():
            adict[fix_path(entry, root_dir)] = entry
        elif recurse and entry.is_dir():
            # sys.stderr.write("get_files({}, , , {})\n".format(entry, recurse))
            get_files(entry, root_dir, adict, recurse)


def quote_for_shell(apath: Path) -> str:
    """
    Returns a string representation of APATH, quoted properly for use in a [ba]sh shell
    script.
    """
    escaped = str(apath).replace("'", "'\"'\"'")
    return "'{}'".format(escaped)


def main(args):
    """Copies files based on ARGS."""
    source_dict = {}
    dest_dict = {}
    source_path = Path(args.source_dir)
    dest_path = Path(args.dest_dir)
    get_files(source_path, source_path, source_dict, args.recursive)
    # print("Source dictionary has {:,} entries.".format(len(source_dict)))
    get_files(dest_path, dest_path, dest_dict, args.recursive)
    # print("Destination dictionary has {:,} entries.".format(len(dest_dict)))

    copy_set = set()
    for key in source_dict:
        if key not in dest_dict:
            copy_set.add(key)

    # print("There are currently {:,} filenames in source but not dest.".format(len(copy_set)))

    dest_dirs = set()
    for fname in copy_set:
        apath: Path = Path(args.dest_dir).joinpath(fname)
        dest_dirs.add(apath.parent)

    # print("Copying to {:,} destination directories.".format(len(dest_dirs)))

    # Currently this does NOT recreate empty directories -- problem??
    for dirname in dest_dirs:
        assert isinstance(dirname, Path)
        print("mkdir -p {}".format(quote_for_shell(dirname)))

    for apath in copy_set:
        print(
            "cp {} {}".format(
                quote_for_shell(Path(args.source_dir).joinpath(apath)),
                quote_for_shell(Path(args.dest_dir).joinpath(apath)),
            )
        )


def tests():
    """Half-assed test suite."""
    actual = quote_for_shell(Path("/home/aflanaga/some random directory"))
    assert actual == "'/home/aflanaga/some random directory'"
    actual = quote_for_shell(
        Path("/home/ontherange/with/single' quotes/ unicode chars\U0001F4A9")
    )
    expected = "'/home/ontherange/with/single'\"'\"' quotes/ unicode chars\U0001F4A9'"
    if actual != expected:
        print("expected: " + expected)
        print("actual:   " + actual)

    fixed = fix_path(Path("/home/aflanagan/tests"), Path("/home/aflanagan"))
    if fixed != "tests".encode("utf-8"):
        print("Expected {}, got {}".format("tests".encode("utf-8"), fixed))
    root_path = "/mnt/userspace/@home/lloyd/passport"
    expected = "Music/Frou Frou/Details/00 Psychobabble.mp3"
    full_path = str(Path(root_path).joinpath(expected))
    fixed = fix_path(Path(full_path), Path(root_path))
    if expected != fixed.decode("utf-8"):
        print("Expected {}, got {}".format(expected, fixed.decode("utf-8")))


if __name__ == "__main__":
    # tests()
    main(check_args())
