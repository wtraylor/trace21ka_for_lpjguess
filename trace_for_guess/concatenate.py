import glob
import os
import shutil
import subprocess

from termcolor import cprint

from trace_for_guess.skip import skip


def cat_files(filelist, out_file):
    """Concatenate a list of NetCDF files using CDO.

    Args:
        filelist: List of input file paths.
        out_file: Path to concatenated output file (will *not* be overwritten).

    Returns:
        The output file (equals `out_file`).

    Raises:
        FileNotFoundError: A file in `filenames` wasn’t found.
        RuntimeError: The command `cdo` is not in the PATH.
    """
    for f in filelist:
        if not os.path.isfile(f):
            raise FileNotFoundError("Input file not found: '%s'" % f)
    if skip(filelist, out_file):
        return out_file
    if shutil.which('cdo') is None:
        raise RuntimeError('The command `cdo` could not be found.')
    cprint('Concatenating files:', 'yellow')
    for f in filelist:
        cprint('\t' + f, 'yellow')
    try:
        subprocess.run(['cdo', 'mergetime'] + filelist + [out_file],
                       check=True)
    except Exception:
        if os.path.isfile(out_file):
            cprint(f"Removing file '{out_file}'.", 'red')
            os.remove(out_file)
        raise
    assert os.path.isfile(out_file)
    cprint(f"Created file '{out_file}'.", 'green')
    return out_file
