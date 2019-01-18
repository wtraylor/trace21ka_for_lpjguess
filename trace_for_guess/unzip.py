import os
from zipfile import ZipFile

from termcolor import cprint


def unzip(filename: str, targetdir: str) -> None:
    """Decompress a zip file into a target directory."""
    cprint("Unzipping '%s' into '%s'..." % (filename, targetdir), 'yellow')
    with ZipFile(filename, "r") as zip_ref:
        zip_ref.extractall(targetdir)


def unzip_files_if_needed(filenames: list, orig_dir: str, unzip_dir: str)
        -> list:
    """Look for files in a directory and unzip them if they’re compressed.

    Args:
        filenames: List with original file names (without .gz suffix).
        orig_dir: Directory where original files are expected.
        unzip_dir: Directory where unzipped files shall be stored.

    Returns:
        List of complete file paths to either the original file in `orig_dir`
        or the unzipped file in `unzip_dir`.

    Raises:
        FileNotFoundError: A file in `filenames` wasn’t found.
    """
    l = list()  # Result list.
    for f in filenames:
        filepath = os.path.join(orig_dir, f)
        if os.path.isfile(f):
            l += [filepath]
        elif os.path.isfile(filepath + ".gz"):
            filepath += ".gz"
            unzip(filename=filepath, targetdir=unzip_dir)
            l += os.path.join(unzip_dir, f)
        else:
            raise RuntimeError("Cannot find original file: '%s'" % path)
    return l
