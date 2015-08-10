#!/usr/bin/env python

import pygit2
from pygit2 import Repository, GIT_SORT_TOPOLOGICAL, GIT_SORT_TIME


def main():
    rtddc = Repository("rtd_datacenter.git")


    obj_type = {pygit2.GIT_OBJ_COMMIT: "commit",
                pygit2.GIT_OBJ_BLOB: "blob",
                pygit2.GIT_OBJ_TAG: "tag",
                pygit2.GIT_OBJ_TREE: "tree"}

    for commit in rtddc.walk(rtddc.head.target,
                             GIT_SORT_TOPOLOGICAL | GIT_SORT_TIME):
        for t in commit.tree:
            otype = rtddc.get(t.id).type
            print obj_type[otype]
            if otype == pygit2.GIT_OBJ_BLOB:
                print "{}: {}".format(t.name, rtddc.get(t.id).size)

if __name__ == '__main__':
    main()
