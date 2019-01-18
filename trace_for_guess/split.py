import os
from glob import glob
from shutil import which
from subprocess import run

from termcolor import cprint


def split_file(filename, out_dir):
    """Split a NetCDF file into 100 years files.

    Create 100 years files (1200 time steps, 12*100 months) for each
    cropped file. The split files are named with a suffix to the original
    file name: *000000.nc,: *000001.nc,: *000002.nc, etc.

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
    cprint(f"Splitting file '{filename}' into 100-years slices...", 'yellow')
    if not os.path.isfile(filename):
        raise FileNotFoundError("Input file doesn’t exist: '%s'" % filename)
    # Remove the file extension from `filename` and use it as a stub in the
    # output directory.
    stub_name = os.path.splitext(os.path.basename(filename))[0]
    stub_path = os.path.join(out_dir, stub_name)
    if which("cdo") is None:
        raise RuntimeError("Executable `cdo` not found.")
    status = run(["cdo", "splitsel,1200", filename, stub_path])
    if status != 0:
        raise RuntimeError("Splitting with `cdo` failed: Bad return code.")
    out_files = glob(stub_path)
    cprint(f'Created the following files: {out_files}.', 'green')
    return out_files
