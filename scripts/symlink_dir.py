#!/bin/python

# Command-line arguments:
# 1) "destination" of symbolic link, equals field name in options.yaml.

from termcolor import cprint
import os
import sys
import yaml

# Name of this script file.
scriptfile = os.path.basename(__file__) + ": "

# We want to find all original TraCE files in the subfolder 'trace_orig'.
# The option 'trace_orig' defined in 'options.yaml' is an absolute or relative
# path. If it already points to the subfolder 'trace_orig', an existing symlink
# or directory is expected.
# The same applies to the CRU files and other directories defined in
# 'options.yaml'.


def create_symlink(dest):
    """
    Create a symbolic link `dest` as relative path, as defined in options.yaml
    """
    orig = yaml.load(open("options.yaml"))["directories"][dest]

    if dest in ["cru_orig", "crujra_orig", "trace_orig"]:
        is_input = True
    elif dest in ["output", "heap"]:
        is_input = False
    else:
        cprint(scriptfile +
               "It is not specified whether '%s' is input or output." % dest)
        sys.exit(1)

    if orig == "":
        cprint(scriptfile +
               "Please define the path to the original TraCE-21ka files under "
               "'%s' in 'options.yaml'." % orig, "red")
        sys.exit(1)

    # Expand path of the user-selected option.
    orig = os.path.expanduser(orig)
    orig = os.path.expandvars(orig)
    orig = os.path.abspath(orig)

    if not os.path.exists(orig):
        cprint(scriptfile +
               "The directory for '%s' as defined in options.yaml does "
               "not exist: '%s'" % (dest, orig), "red")
        if is_input:
            cprint("I cannot proceed without that input directory.", "red")
            sys.exit(1)
        else:
            cprint("I will create that directory.", "green")
            os.makedirs(orig)

    if os.path.islink(dest):
        # The symlink `dest` must have been created by this script or by the
        # user manually (`ln -s ...`).
        # We will just replace it if it is not pointing to `origin`.
        if os.readlink(dest) != orig:
            os.remove(dest)
        else:
            sys.exit(0) # Nothing to do.
    elif os.path.isdir(dest):
        cprint(scriptfile + "'%s' is an existing subdirectory." % dest, "red")
        cprint("I cannot create a symbolic link there. Please remove the "
               "directory: '%s'" % os.path.abspath(dest), "red")
        sys.exit(1)
    elif os.path.isfile(dest):
        cprint(scriptfile + "'%s' is an existing file." % dest, "red")
        cprint("I cannot create a symbolic link there. Please remove the "
               "file: '%s'" % os.path.abspath(dest), "red")
        sys.exit(1)

    # Until here, the script has exited if we don’t need a new symbolic link.

    cprint(scriptfile +
           "Creating symbolic link from '%s' to subdirectory '%s'."
           % (orig, dest), "green")
    os.symlink(orig, os.path.abspath(dest))

if len(sys.argv) != 2:
    cprint(scriptfile + "Please provide symlink destination as argument.",
           "red")
    sys.exit(1)

create_symlink(sys.argv[1])
