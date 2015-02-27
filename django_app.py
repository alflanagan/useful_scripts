#/usr/bin/env python2.7
# $Id: django_app.py 8 2013-06-21 15:18:59Z aflanagan $
# $URL: http://rich-svn1.wme.owhc.net/repos/django_analyze/trunk/django_app.py $
"""Classes to model django applications and models, etc."""
from __future__ import unicode_literals, print_function

__all__ = ["DjangoApp", "DjangoModelClass", "DjangoProject"]

import os
import sys


class DjangoProject(object):
    """A complete django project, containing one or more Django apps."""
    MODEL_FILE = 'models.py'
    EXCLUDED_SEARCH_DIRS = set(['.svn'])

    def __init__(self, project_dir):
        """Create object for the project located in directory project_dir"""
        self.directory = project_dir

    def _model_files(self, parent_dir):
        """Returns a list of all model files in parent_dir or its children"""
        dcontents = os.listdir(parent_dir)
        results = []
        if self.MODEL_FILE in dcontents:
            results.append(os.path.join(parent_dir, self.MODEL_FILE))
        for dname in [d for d in dcontents if os.path.isdir(os.path.join(parent_dir, d))]:
            if not dname in self.EXCLUDED_SEARCH_DIRS:
                results.extend(self._model_files(os.path.join(parent_dir, dname)))
        return results

    @property
    def apps(self):
        """A list of the names of this project's applications."""
        files = self._model_files(self.directory)
        #ok, get paths relative to project directory
        files = [fname.replace(self.directory, '') for fname in files]
        #strip out 'models.py' part
        dirs = [os.path.dirname(f) for f in files]
        #remove leading / if any
        dirs = [d[1:] if d.startswith(os.path.sep) else d for d in dirs]
        #replace /es with periods
        dirs = [d.replace(os.path.pathsep, '.') for d in dirs]
        return dirs


class DjangoModelClass(object):
    "Information about a model class in an app."
    def __init__(self, django_app, class_name):
        self.app = django_app
        isinstance(self.app, DjangoApp)
        self.name = class_name

    @property
    def fields(self):
        """
        returns list of field names for class
        """
        old_syspath = sys.path
        try:
            sys.path.insert(0, self.app.project.directory)
            get_fields = '''
from {0}.models import {1}
m = {1}._meta
app_label = m.app_label
fieldlist = [unicode(x) for x in m.get_all_field_names()]
'''
            run_code = get_fields.format(self.app.name, self.name)
            #print(run_code)
            exec(run_code, locals(), globals())  #pylint: disable=exec-statement
        finally:
            sys.path = old_syspath
        return fieldlist #pylint: disable=E0602


class DjangoApp(object):
    "Information about a single Django application."

    #TODO: Need a context wrapper to set our directory to front of sys.path,
    #<do something>, and set it back to original value
    def __init__(self, django_proj, app_directory):
        """Creates instance of application located in app_directory in project django_proj"""
        self.project = django_proj
        isinstance(self.project, DjangoProject)
        self.directory = app_directory

    @property
    def name(self):
        """Returns the application name in dotted form"""
        #just to guard against weirdness in setting directory
        dirname = os.path.normpath(self.directory)
        return dirname.replace('/', '.')

    @property
    def model_classes(self):
        """Returns a list with the names of all model classes"""
        classes = []

        old_syspath = sys.path
        try:
            sys.path.insert(0, self.project.directory)
            template_code = '''
from {0} import models
for d in dir(models):
    try:
        #check: are we defined in this module?
        if eval("models." + d + ".__module__") == models.__name__:
            classes.append(d)
    except AttributeError:
        pass
'''
            run_code = template_code.format(self.name)
            #print(run_code)
            exec(run_code, globals(), locals()) #pylint: disable=exec-statement
        finally:
            sys.path = old_syspath
        return [DjangoModelClass(self, unicode(c)) for c in classes]


if __name__ == '__main__':
    from django.conf import settings
    settings.configure()

    #TODO: set up actual honest-to-God test data
    proj1 = DjangoProject('../toms/dj15port')
    for app in proj1.apps:
        this_app = DjangoApp(proj1, app)
        print(this_app.name)
        if this_app.model_classes:
            sys.stdout.write("    ")
            for c in this_app.model_classes:
                sys.stdout.write(" " + c.name)
            sys.stdout.write("\n")
            sys.stdout.write("     " + this_app.model_classes[0].name + ": ")
            for fld in this_app.model_classes[0].fields:
                sys.stdout.write(" " + fld)
            sys.stdout.write("\n")