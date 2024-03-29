# SPDX-FileCopyrightText: 2021 Wolfgang Traylor <wolfgang.traylor@senckenberg.de>
#
# SPDX-License-Identifier: MIT

import os
import shutil
import subprocess
from glob import glob

from termcolor import cprint

from trace_for_guess.skip import skip


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
    if not os.path.isdir(out_dir):
        cprint(f"Directory '{out_dir}' does not exist yet. I will create it.",
               'yellow')
        os.makedirs(out_dir)
    # Remove the file extension from `filename` and use it as a stub in the
    # output directory.
    stub_name = os.path.splitext(os.path.basename(filename))[0] + '_'
    stub_path = os.path.join(out_dir, stub_name)
    # We assume that if there are any files obviously created by `cdo
    # splitsel`, these will be complete. If the creation of files had been
    # interrupted, all files would have been deleted in the except-block.
    existing_files = glob(stub_path + '*')
    if existing_files and skip(filename, existing_files):
        return existing_files
    cprint(f"Splitting file '{filename}' into 100-years slices...", 'yellow')
    if shutil.which("cdo") is None:
        raise RuntimeError("Executable `cdo` not found.")
    try:
        years = 100
        timesteps = 12 * years
        subprocess.run(['cdo', f'splitsel,{timesteps}', filename, stub_path],
                       check=True)
    except Exception:
        for f in glob(stub_path + '*'):
            cprint(f"Removing file '{f}'.", 'red')
            os.remove(f)
        raise
    out_files = glob(stub_path + '*')
    if not out_files:
        raise RuntimeError('The command `cdo splitsel` didn’t produce an '
                           'output files.')
    cprint('Created the following files:', 'green')
    for f in out_files:
        cprint('\t' + f, 'green')
    return out_files
