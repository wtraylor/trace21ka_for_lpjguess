#!/bin/python

import os
import sys
import yaml

# We want to find all original TraCE files in the subfolder 'trace_orig'.
# The option 'trace_orig' defined in 'options.yaml' is an absolute or relative
# path. If it already points to the subfolder 'trace_orig', an existing symlink
# or directory is expected.

trace_orig = yaml.load(open("options.yaml"))["trace_orig"]

if trace_orig == "":
    print("Please define the path to the original TraCE-21ka files under "
          "'trace_orig' in 'options.yaml'.")
    sys.exit(1)

# Expand path of the user-selected option.
trace_orig = os.path.expanduser(trace_orig)
trace_orig = os.path.expandvars(trace_orig)
trace_orig = os.path.abspath(trace_orig)

if not os.path.exists(trace_orig):
    print("The directory for 'trace_orig' as defined in options.yaml does",
          "not exist: '%s'" % trace_orig)
    sys.exit(1)

if os.path.islink("trace_orig"):
    # The symlink 'trace_orig' must have been created by this script or by the
    # user manually (`ln -s ...`).
    # Check if the existing symbolic link is valid or needs to be replaced.
    if os.path.isdir(os.path.realpath("trace_orig")):
        print("Symbolic link 'trace_orig' already exists (->'%s')." %
              os.path.realpath("trace_orig"))
        if trace_orig != os.path.realpath("trace_orig"):
            print("It does not match the path given in options.yaml, so it "
                  "will be replaced.")
            os.remove("trace_orig")
        else:
            print("The existing link matches the path in 'options.yaml'. "
                  "Nothing to do.")
            sys.exit(0)
        if trace_orig == os.path.abspath("trace_orig"):
            print("You seem to have manually created the symbolic link for "
                  "'trace_original'. I will leave it untouched.")
            sys.exit(0)
    else:
        print("Existing symbolic link 'trace_orig' (->'%s') is invalid and "
              "will be replaced" % trace_orig)
        os.remove("trace_orig")
elif os.path.isdir("trace_orig"):
    print("'trace_orig' is an existing subdirectory.")
    if trace_orig == os.path.abspath("trace_orig"):
        print("We will leave it untouched because it matches the path given "
              "in 'options.yaml'.")
        sys.exit(0)
    else:
        print("I cannot create a symbolic link there. Please remove the "
              "directory: '%s'" % os.path.abspath("trace_orig"))
        sys.exit(1)
elif os.path.isfile("trace_orig"):
    print("'trace_orig' exists, but is a file. Please remove it.")
    sys.exit(1)

# Until here, the script has exited if we don’t need a new symbolic link.

print("Creating symbolic link from '%s' to subdirectory 'trace_orig'."
      % trace_orig)
os.symlink(trace_orig, os.path.abspath("trace_orig"))
