import os
from zipfile import ZipFile

from termcolor import cprint


def unzip(filename, targetdir):
    """Decompress a zip file into a target directory."""
    cprint("Unzipping '%s' into '%s'..." % (filename, targetdir), 'yellow')
    with ZipFile(filename, "r") as zip_ref:
        zip_ref.extractall(targetdir)


def unzip_files_if_needed(filenames, unzip_dir):
    """Seach files in the input folders and unzip them if they’re compressed.

    Here we assume that the zip archive was named after the contained file by
    appending a '.gz' suffix.

    Args:
        filenames: List with original file names (without .gz suffix).
        unzip_dir: Directory where unzipped files shall be stored.

    Returns:
        List of complete file paths to either the original file or the unzipped
        file in `unzip_dir`.

    Raises:
        FileNotFoundError: A file in `filenames` wasn’t found.
    """
    l = list()  # Result list.
    for f in filenames:
        try:
            l += [find_files(f)]
        except FileNotFoundError:
            try:
                filepath = find_files(f + '.gz')
                unzip(filename=filepath, targetdir=unzip_dir)
                l += os.path.join(unzip_dir, f)
            except FileNotFoundError:
                raise FileNotFoundError("Unable to find plain or compressed "
                                        f"file '{f}' in input directories.")
    return l
