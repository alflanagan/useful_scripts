#!/usr/bin/env python3
"""Script to print out class heirarchy in a python module."""
import sys
import ast
from collections import defaultdict


class ModuleNotFoundError(Exception):
    """Exception raised when we can't find a module for a python file."""
    def __str__(self):
        if self.args:
            return "Unable to get a module name from '{}'.".format(self.args[0])
        return "Unable to get a module name."


class ClassDefVisitor(ast.NodeVisitor):  # pylint: disable=R0903
    """A node visitor class that saves information about classes and their base classes."""

    def __init__(self):
        self.class_dict = {}
        self.__module = ""

    def visit_ClassDef(self, a_node):  # pylint: disable=C0103
        cname = a_node.name  # name of a class
        full_name = "{}.{}".format(self.module, cname)
        if full_name in self.class_dict:
            sys.stderr.write("Duplicate class name in input: {}.\n".format(full_name))
            sys.exit(1)
        # TODO: Need to do whatever ast voodoo gets full class name for base class
        self.class_dict[full_name] = [base.id
                                      for base
                                      in a_node.bases
                                      if isinstance(base, ast.Name)]

    @staticmethod
    def _get_package_from_dir(path, module=""):
        """Walks up the directory tree in `path`, adding to `module` until it encounters a
        directory with on "__init__.py" file.

        """
        # TODO: there is probably an official way to do this that does not rely on directory
        # structure -- check out loader classes
        if os.path.exists(os.path.join(path, "__init__.py")):
            new_module = os.path.basename(path)
            if module:
                new_module = "{}.{}".format(new_module, module)
            return ClassDefVisitor._get_package_from_dir(os.path.dirname(path),
                                                         new_module)
        else:
            return module

    @property
    def module(self):
        return self.__module

    def set_module_from(self, file_or_dir):
        if os.path.isfile(file_or_dir):
            module_file = os.path.basename(file_or_dir)
            if module_file.endswith(".py"):
                final_module = module_file[:-3]
            elif module_file.endswith(".pyc") or module_file.endswith(".pyo"):
                final_module = module_file[:-4]
            else:
                final_module = module_file
            self.__module = ClassDefVisitor._get_package_from_dir(os.path.dirname(file_or_dir),
                                                                  final_module)
        elif os.path.isdir(file_or_dir):
            self.__module = ClassDefVisitor._get_package_from_dir(file_or_dir)
        else:
            raise ModuleNotFoundError(file_or_dir)


def printkids(classname, indent_level, parent_dict):
    indent = '   '
    print("{}{}".format(indent * indent_level, classname))
    kids = [kid for kid in parent_dict[classname]]
    kids.sort()
    for kid in kids:
        printkids(kid, indent_level + 1, parent_dict)


def main():
    visitor = ClassDefVisitor()
    parents = defaultdict(list)
    for fname in sys.argv[1:]:
        # TODO: How do I handle an encoding declaration here? ast.parse() seems to fail.
        with open(fname, "r") as src_in:
            ast_node = ast.parse(src_in.read(), fname)
            visitor.set_module_from(fname)
            visitor.visit(ast_node)
    # here we magically organize the class dictionary
    for key in visitor.class_dict:
        for value in visitor.class_dict[key]:
            parents[value].append(key)
    # must find classes with no parents
    all_kids = set()
    for parent in parents:
        for kid in parents[parent]:
            all_kids.add(kid)
    for top_level in set(parents.keys()) - all_kids:
        printkids(top_level, 0, parents)


if __name__ == '__main__':
    import os
    if len(sys.argv) <= 1:
        sys.stderr.write("Usage: {} python_files".format(os.path.basename(sys.argv[0])))
    main()
