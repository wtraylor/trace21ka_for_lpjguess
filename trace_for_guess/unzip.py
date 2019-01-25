import gzip
import os
import re
import shutil

from termcolor import cprint

from trace_for_guess.find_input import find_files


def gunzip(filename, targetdir):
    """Decompress a gzip-compressed file into a target directory.
    Args:
        filename: Full path to gzip file.
        targetdir: Directory to decompress file into.

    Returns:
        The output file name.

    Raises:
        FileNotFoundError: `filename` does not exist.
    """
    # We delete the .gz suffix and put the decompressed file into `targetdir`.
    if not os.path.isfile(filename):
        raise FileNotFoundError(f"File '{filename}' does not exist.")
    targetfile = os.path.join(
        targetdir, re.sub('\\.gz$', '', os.path.basename(filename))
    )
    cprint(f"Decompressing '{filename}' to '{targetdir}'...", 'yellow')
    try:
        with open(targetfile, 'xb') as o, gzip.open(filename, 'rb') as i:
            shutil.copyfileobj(i, o)
    except Exception:
        # Clean up target file.
        if os.path.isfile(targetfile):
            cprint(f"Removing file '{targetfile}'...", 'red')
            os.remove(targetfile)
        raise


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
    result = list()  # Result list.
    if not os.path.isdir(unzip_dir):
        cprint(f"Creating directory '{unzip_dir}'.", 'yellow')
        os.makedirs(unzip_dir)
    for f in filenames:
        try:
            # Try to find unzipped file.
            found = find_files(f)
            result += [found]
            cprint(f"Found file: '{found}'", 'cyan')
            continue  # On to the next file.
        except FileNotFoundError:
            pass
        try:
            # Try to find the zipped file.
            filepath = find_files(f + '.gz')
            cprint(f"Found zipped file: '{filepath}'", 'cyan')
            result += [gunzip(filename=filepath, targetdir=unzip_dir)]
        except FileNotFoundError as ex:
            cprint("Unable to find plain or compressed "
                   f"file '{f}' in input directories.", 'red')
            raise ex
    assert(len(result) == len(filenames))
    return result
