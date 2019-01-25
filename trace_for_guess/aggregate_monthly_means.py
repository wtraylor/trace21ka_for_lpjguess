import os.path
import shutil
import subprocess

from termcolor import cprint

from trace_for_guess.skip import skip


def aggregate_monthly_means(in_file, out_file):
    """Calculate the mean over all years for each month using CDO.

    The resulting file has then exactly 12 values per grid cell: one
    average per month.

    Args:
        in_file: Input NetCDF file path.
        out_file: Path to output file (will *not* be overwritten).

    Returns:
        The output file (equals `out_file`).

    Raises:
        FileNotFoundError: The file `in_file` wasn’t found.
        RuntimeError: The `cdo` command is not in the PATH.
        RuntimeError: The `cdo` command returned an error or the output
            file wasn’t created.
    """
    if not os.path.isfile(in_file):
        raise FileNotFoundError("Input file doesn’t exist: '%s'" % in_file)
    if shutil.which('cdo') is None:
        raise RuntimeError('Executable `cdo` not found.')
    if skip(in_file, out_file):
        return out_file
    cprint(f"Aggregating monthly means from '{in_file}', writing to "
           "'{out_file}'...", 'yellow')
    try:
        subprocess.run(['cdo', 'ymonmean', in_file, out_file], check=True)
    except Exception:
        if os.path.isfile(out_file):
            cprint(f"Removing file '{out_file}'.", 'red')
            os.remove(out_file)
        raise
    if not os.path.isfile(out_file):
        raise RuntimeError('Aggregating with `cdo ymonmean` failed: No output '
                           'file created.')
    cprint(f"Successfully created '{out_file}'.", 'green')
    return out_file
