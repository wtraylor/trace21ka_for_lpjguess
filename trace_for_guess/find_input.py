# SPDX-FileCopyrightText: 2021 Wolfgang Traylor <wolfgang.traylor@senckenberg.de>
#
# SPDX-License-Identifier: MIT

import glob
import os

import yaml


def find_files(filenames):
    """Find file(s) recursively in the directories given in 'options.yaml'.

    Additionally to input directories search also the 'input' subdirectory of
    the `heap` directory. It contains unzipped and PRECT files.

    Args:
        filenames: List of filenames (or one file name string).

    Returns:
        List with the full paths of all given filenames.

    Raises:
        FileNotFoundError: One of the requested files could not be found.
        NotADirectoryError: One of the input directory paths is invalid.
        RuntimeError: No directories in 'options.yaml'.
        ValueError: The input list is empty or one of the file names is an
            empty string.
    """
    opts = yaml.load(open('options.yaml'))
    heap_input = os.path.join(opts['directories']['heap'], '0_input')
    dirs = ['external_files', heap_input]
    if not dirs:
        raise RuntimeError("No input directories defined in 'options.yaml'.")
    # Expand '~' for home directory and environment variables like '$HOME'.
    dirs[:] = [os.path.expanduser(os.path.expandvars(d)) for d in dirs]
    # Check if each directory exists.
    for d in dirs:
        if not os.path.isdir(d):
            raise NotADirectoryError("This path for input files from "
                                     "'options.yaml' is not a directory: "
                                     "'%s'." % d)
    # Allow for single file path string as input instead of a list.
    is_list = isinstance(filenames, list)
    if not is_list:
        filenames = [filenames]
    if len(filenames) == 0:
        raise ValueError("Parameter 'filenames' is an empty list.")
    result = list()
    for f in filenames:
        if not f:
            raise ValueError("An input filename is an empty string.")
        found = False
        # Iterate through all directories and search with glob through them.
        iterator = iter(dirs)
        while not found:
            try:
                d = next(iterator)
            except StopIteration:
                break
            # Search first within the directory d directly and then look in all
            # subdirectories.
            found = (glob.glob(os.path.join(d, f))
                     + glob.glob(os.path.join(d, '**', f)))
            if found:
                result += [found[0]]  # Take the first hit.
                break  # Leave directory loop.
        if not found:
            raise FileNotFoundError(f"Could not find file '{f}' anywhere in "
                                    f"input directories {dirs}.")
    assert len(result) == len(filenames)
    # If the argument was only one string, we shall return only a string and
    # not a list.
    if is_list:
        return result
    else:
        return result[0]
