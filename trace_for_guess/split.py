import os
import shutil
import subprocess
from glob import glob

from termcolor import cprint


def split_file(filename, out_dir):
    """Split a NetCDF file into 100 years files.

    Create 100 years files (1200 time steps, 12*100 months) for each
    cropped file. The split files are named with a suffix to the original
    file name: *_000000.nc,: *_000001.nc,: *_000002.nc, etc.

    There is no check if the output files already exist.

    Args:
        filename: Path of input NetCDF file.
        out_dir: Output directory path.

    Raises:
        FileNotFoundError: If `filename` or `out_dir` was not found.
        RuntimeError: If CDO command failed.
        RuntimeError: If `cdo` command is not in the PATH.

    Returns:
        List of paths of newly creatd files, each 100 years long (or
        shorter).
    """
    if not os.path.isfile(filename):
        raise FileNotFoundError("Input file doesn’t exist: '%s'" % filename)
    # Remove the file extension from `filename` and use it as a stub in the
    # output directory.
    stub_name = os.path.splitext(os.path.basename(filename))[0] + '_'
    stub_path = os.path.join(out_dir, stub_name)
    existing_files = os.glob(stub_path + '*')
    if existing_files:
        for f in existing_files:
            cprint(f'Skipping: {f}', 'cyan')
        return existing_files
    cprint(f"Splitting file '{filename}' into 100-years slices...", 'yellow')
    if shutil.which("cdo") is None:
        raise RuntimeError("Executable `cdo` not found.")
    try:
        subprocess.run(["cdo", "splitsel,1200", filename, stub_path],
                       check=True)
    except:
        for f in glob(stub_path + '*'):
            cprint(f"Removing file '{f}'.", 'red')
            os.remove(f)
        raise
    out_files = glob(stub_path + '*')
    if not out_files:
        raise RuntimeError('The command `cdo splitsel` didn’t produce an '
                           'output files.')
    cprint(f'Created the following files: {out_files}', 'green')
    return out_files
