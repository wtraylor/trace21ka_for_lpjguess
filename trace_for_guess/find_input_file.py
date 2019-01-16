import os


def find_file(filename):
    """Search for filename in all input directories of 'options.yaml'.

    Returns:
        The full path of the file name.

    Raises:
        FileNotFoundError: `filename` was not found.
    """
