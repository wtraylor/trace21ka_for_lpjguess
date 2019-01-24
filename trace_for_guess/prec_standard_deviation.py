import os
import shutil
import subprocess

from termcolor import cprint


def get_prec_standard_deviation(filelist, out_file):
    """Calculate day-to-day standard deviation of precipitation for each month.

    Args:
        filelist: List of input NetCDF file paths.
        out_file: Path to output file to be created.

    Raises:
        FileNotFoundError: A file path in `filelist` cannot be found.
        RuntimeError: `cdo` command is not in the PATH.

    Returns:
        The created output file (equals `out_file`).
    """
    if not shutil.which('cdo'):
        raise RuntimeError('`cdo` command is not in the PATH.')
    for f in filelist:
        if not os.path.isfile(f):
            raise FileNotFoundError(f"Cannot find file '{f}'.")
    if os.path.isfile(out_file):
        cprint(f"Skipping: '{out_file}'", 'cyan')
        return out_file
    try:
        cprint('Calculating standard deviation of precipitation...', 'yellow')
        subprocess.run(['cdo', 'ymonmean', '-monstd', '-cat', filelist[0],
                        '-daysum'] + filelist[1:] + [out_file], check=True)
    except:
        if os.path.isfile(out_file):
            cprint(f"Removing file '{out_file}'.", 'red')
            os.remove(out_file)
        raise
    cprint(f"Successfully created '{out_file}'.", 'green')
    return out_file
