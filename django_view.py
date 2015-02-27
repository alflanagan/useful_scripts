#!/usr/bin/env python2.7
# $Id: main_gui.py 11 2013-06-21 15:31:19Z aflanagan $
# $URL: http://rich-svn1.wme.owhc.net/repos/django_analyze/trunk/ui/main_gui.py $
from Tkinter import *
import tkFileDialog
import ttk
import time
import sys

from django_app import DjangoApp, DjangoProject, DjangoModelClass

class SelectableListBox(Listbox):
    """Will be a list box which displays a list, triggers callback when item selected."""
    #hide listvariable, configure calls
    pass


class MainWindow(object):

    """Class to organize setting up UI.

    TKinter setup is not very object-oriented, but we can tame the monster
    a little bit.

    """
    LBOX_FRAME_HEIGHT = 300
    "Height of frame for listboxes, in pixels. Determines overall UI height."
    LBOX_FRAME_WIDTH = 200
    "Width of frame for listboxes, in pixels. Determines overall UI width."

    def __init__(self, root_window):
        self.root = root_window
        self.base_frame = ttk.Frame(root)
        self.proj_directory = StringVar()
        "Directory which is top level of django project, selected by user"
        self.apps_list = StringVar()
        "list of all applications for selected project"
        self.models_list = StringVar()
        "list of model classes for the selected application"
        self.fields_list = StringVar()
        "list of fields for the selected model class"
        self.build_select_project()
        self.build_output_frame()
        self.grid_widgets()
        self.configure_grid()

    #remarkably, there appears no way to get the list box variable from the list box object
    @staticmethod
    def set_lbox_to_list(lbox, lboxvar, valuelist):
        "Sets up listbox to display list in valuelist"
        lbox.configure(height=len(valuelist))
        lboxvar.set(tuple(valuelist))
        for i in range(0, len(valuelist), 2):
            lbox.itemconfigure(i, background="#f0f0ff")

    def choose_dir(self):
        asked = tkFileDialog.askdirectory()
        self.proj_directory.set(asked)
        self.outproject = DjangoProject(asked)
        applist = self.outproject.apps[:]  #copy for sorting
        applist.sort()
        self.set_lbox_to_list(self.apps_lbox, self.apps_list, applist)

    @staticmethod
    def get_lbox_current_value(lbox, listvar):
        #note curselection returns tuple, even though only one should be selected
        selected = lbox.curselection()[0]
        #ugh. hackish. thanks, Tkinter
        return eval(listvar.get())[int(selected)]

    def select_app(self, evt):
        app_name = self.get_lbox_current_value(self.apps_lbox, self.apps_list)
        self.current_app = DjangoApp(self.outproject, app_name)
        modlist = [mdl.name for mdl in self.current_app.model_classes]
        modlist.sort()
        self.set_lbox_to_list(self.models_lbox, self.models_list, modlist)
        #don't keep fields from previous selected model
        self.set_lbox_to_list(self.fields_lbox, self.fields_list, [])

    def select_model(self, evt):
        model_name = self.get_lbox_current_value(self.models_lbox, self.models_list)
        self.current_model = DjangoModelClass(self.current_app, model_name)
        fldlist = self.current_model.fields[:]  #copy to sort
        fldlist.sort()
        self.set_lbox_to_list(self.fields_lbox, self.fields_list, fldlist)

    def build_select_project(self):
        self.lbl1 = ttk.Label(self.base_frame, text="Select a django root directory (with manage.py)", padding=(5, 5))
        self.direntry = ttk.Entry(self.base_frame, width=40, textvariable=self.proj_directory)
        self.fpick = ttk.Button(self.base_frame, text="...", command=self.choose_dir)

    def build_output_frame(self):
        self.output_frame = ttk.Frame(self.base_frame)
        self.apps_frame = ttk.LabelFrame(self.output_frame, text="Django Apps")
        self.apps_lbox = Listbox(self.apps_frame, height=10, listvariable=self.apps_list)
        self.apps_lbox.bind('<<ListboxSelect>>', self.select_app)
        self.models_frame = ttk.LabelFrame(self.output_frame, text="Model Classes")
        self.models_lbox = Listbox(self.models_frame, height=10, listvariable=self.models_list)
        self.models_lbox.bind('<<ListboxSelect>>', self.select_model)
        self.fields_frame = ttk.LabelFrame(self.output_frame, text="Class Fields")
        self.fields_lbox = Listbox(self.fields_frame, height=10, listvariable=self.fields_list)

    def grid_widgets(self):
        self.base_frame.grid(row=0, column=0, sticky=(N, S, E, W))
        self.lbl1.grid(row=0, column=0, sticky=(E))
        self.direntry.grid(row=0, column=1, columnspan=2, sticky=(E, W))
        self.fpick.grid(row=0, column=4)
        self.output_frame.grid(row=1, column=0, columnspan=5, sticky=(N, S, E, W))
        self.apps_frame.grid(row=0, column=0, sticky=(N, S, E, W))
        self.apps_lbox.grid(row=0, column=0, sticky=(N, S, E, W))
        self.models_frame.grid(row=0, column=1, sticky=(N, S, E, W))
        self.models_lbox.grid(row=0, column=0, sticky=(N, S, E, W))
        self.fields_frame.grid(row=0, column=2, sticky=(N, S, E, W))
        self.fields_lbox.grid(row=0, column=0, sticky=(N, S, E, W))

    def configure_grid(self):
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        self.base_frame.rowconfigure(0, weight=1)
        self.base_frame.rowconfigure(1, weight=15)
        self.base_frame.columnconfigure(0, weight=1)
        self.base_frame.columnconfigure(1, weight=1)
        self.base_frame.columnconfigure(2, weight=1)
        self.base_frame.columnconfigure(3, weight=1)
        self.output_frame.columnconfigure('all', minsize=self.LBOX_FRAME_WIDTH, weight=1)
        self.output_frame.rowconfigure(0, minsize=self.LBOX_FRAME_HEIGHT, weight=1)
        self.apps_frame.columnconfigure(0, weight=1)
        self.apps_frame.rowconfigure(0, weight=1)
        self.models_frame.columnconfigure(0, weight=1)
        self.models_frame.rowconfigure(0, weight=1)
        self.fields_frame.columnconfigure(0, weight=1)
        self.fields_frame.rowconfigure(0, weight=1)


if __name__ == '__main__':
    #do required Django setup
    from django.conf import settings
    settings.configure()

    root = Tk()
    my_app = MainWindow(root)

    root.mainloop()
