import os

from termcolor import cprint


def is_younger(filename, other_files):
    """Check if the modification of a given file is younger than other file(s).

    Args:
        filename: Path to the file in question.
        other_files: A list of files to compare against. It can also be a
            single file.

    Returns:
        True if none of the other files have been modified since the the file
        in question has been modified. False if at least one of the other files
        has a younger modification timestamp.

    Raises:
        FileNotFoundError: One of the given files does not exist.
    """
    if not os.path.isfile(filename):
        raise FileNotFoundError(f"File not found: '{filename}'")
    # Allow for single file path string as input instead of a list.
    if not isinstance(other_files, list):
        other_files = [other_files]
    for f in other_files:
        if not os.path.isfile(f):
            raise FileNotFoundError("File not found: '%s'" % f)
    for f in other_files:
        if os.path.getmtime(f) > os.path.getmtime(filename):
            return False
    return True


def remove_outdated_files(filelist):
    """Remove a list of files with a message.

    Note that not all given files need to exist.

    Args:
        filelist: A list of file paths.
    """
    for f in filelist:
        if os.path.isfile(f):
            cprint(f"Removing outdated file '{f}'.", 'red')
            os.remove(f)


def skip(in_files, out_files):
    """Check if output file(s) can be skipped and delete output files if needed.

    This function is like a Makefile rule: The input files are the “targets”
    and the output files are the “prerequisites.”
    If only one input file is younger than an output file, all output files are
    removed, and `False` is returned.

    Args:
        in_files: List of files that are used to create `out_files`. Can also
            be a single file path.
        out_files: List of files that depend on `in_files`. Can also be a
            single file path. There is no error if one of the output files
            doesn’t exist.

    Returns:
        True if producing output files can be skipped.

    Raises:
        FileNotFoundError: One of the input files was not found.
    """
    # Allow for single file path string as input instead of a list.
    if not isinstance(in_files, list):
        in_files = [in_files]
    if not isinstance(out_files, list):
        out_files = [out_files]
    for f in in_files:
        if not os.path.isfile(f):
            raise FileNotFoundError("File not found: '%s'" % f)
    for i in in_files:
        for o in out_files:
            if os.path.isfile(o):
                if is_younger(i, o):
                    remove_outdated_files(out_files)
                    return False
            else:
                # If one output file doesn’t exist, this file must definitely
                # be created.
                remove_outdated_files(out_files)
                return False
    for f in out_files:
        cprint(f"Skipping: '{f}'", 'cyan')
    return True
