#!/bin/python

from termcolor import cprint
import os
import sys
import yaml

# We want to find all original TraCE files in the subfolder 'trace_orig'.
# The option 'trace_orig' defined in 'options.yaml' is an absolute or relative
# path. If it already points to the subfolder 'trace_orig', an existing symlink
# or directory is expected.

trace_orig = yaml.load(open("options.yaml"))["trace_orig"]

if trace_orig == "":
    cprint("Please define the path to the original TraCE-21ka files under "
           "'trace_orig' in 'options.yaml'.", "red")
    sys.exit(1)

# Expand path of the user-selected option.
trace_orig = os.path.expanduser(trace_orig)
trace_orig = os.path.expandvars(trace_orig)
trace_orig = os.path.abspath(trace_orig)

if not os.path.exists(trace_orig):
    cprint("The directory for 'trace_orig' as defined in options.yaml does",
           "not exist: '%s'" % trace_orig, "red")
    sys.exit(1)

if os.path.islink("trace_orig"):
    # The symlink 'trace_orig' must have been created by this script or by the
    # user manually (`ln -s ...`).
    # We will just replace it.
    os.remove("trace_orig")
elif os.path.isdir("trace_orig"):
    cprint("'trace_orig' is an existing subdirectory.", "red")
    cprint("I cannot create a symbolic link there. Please remove the "
           "directory: '%s'" % os.path.abspath("trace_orig"), "red")
    sys.exit(1)
elif os.path.isfile("trace_orig"):
    cprint("'trace_orig' is an existing file.", "red")
    cprint("I cannot create a symbolic link there. Please remove the "
           "file: '%s'" % os.path.abspath("trace_orig"), "red")
    sys.exit(1)

# Until here, the script has exited if we don’t need a new symbolic link.

cprint("Creating symbolic link from '%s' to subdirectory 'trace_orig'."
       % trace_orig, "green")
os.symlink(trace_orig, os.path.abspath("trace_orig"))
