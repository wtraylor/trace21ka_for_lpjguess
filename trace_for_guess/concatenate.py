import os
import shutil
import subprocess

from termcolor import cprint


def cat_files(filelist, out_file):
    """Concatenate a list of NetCDF files using NCO (i.e. ncrcat).

    Args:
        filelist: List of input file paths.
        out_file: Path to concatenated output file (will *not* be overwritten).

    Returns:
        The output file (equals `out_file`).

    Raises:
        FileNotFoundError: A file in `filenames` wasn’t found.
        RuntimeError: The command `ncrcat` is not in the PATH.
        RuntimeError: The command `ncrcat` produced an error or the output
            file wasn’t created.
    """
    for f in filelist:
        if not os.path.isfile(f):
            raise FileNotFoundError("Input file not found: '%s'" % f)
    if os.path.exists(out_file):
        cprint(f"Output file '{out_file}' already exists. Skipping.", 'cyan')
        return out_file
    if shutil.which("ncrcat") is None:
        raise RuntimeError('The command `ncrcat` could not be found.')
    cprint(f"Concatenating files {filelist} to '{out_file}'...", 'yellow')
    try:
        subprocess.run(['ncrcat'] + filelist + [out_file], check=True)
    except:
        if os.path.isfile(out_file):
            cprint(f"Removing file '{out_file}'.", 'red')
            os.remove(out_file)
        raise
    if not os.path.isfile(out_file):
        raise RuntimeError('The command `ncrcat` didn’t produce an output '
                        'file.')
    cprint(f"Created file '{out_file}'.", 'green')
    return out_file
