import os
import shutil
import subprocess

from termcolor import cprint
import yaml

from trace_for_guess.skip import skip


def compress_netcdf(in_file, out_file):
    """Compress a NetCDF file using NCO using lossless deflate compression.

    Args:
        in_file: Input NetCDF file.
        out_file: Output NetCDF file.

    Returns:
        Path to output file (equals `out_file`).

    Raises:
        FileNotFoundError: `in_file` does not exist.
        RuntimeError: The command `ncks` is not in the PATH.
    """
    if not os.path.isfile(in_file):
        raise FileNotFoundError(f"Cannot find input file '{in_file}'.")
    if skip(in_file, out_file):
        return out_file
    if not shutil.which('ncks'):
        raise RuntimeError(f'The command `ncks` is not in the PATH.')
    compression_level = yaml.load(open('options.yaml'))['compression_level']
    cprint(f"Compressing file '{in_file}'...", 'yellow')
    try:
        subprocess.run(['ncks', '--deflate', str(compression_level), in_file,
                        out_file], check=True)
    except Exception:
        if os.path.isfile(out_file):
            cprint(f"Removing file '{out_file}'.", 'red')
            os.remove(out_file)
        raise
    assert(os.path.isfile(out_file))
    cprint(f"Successfully created file: '{out_file}'", 'green')
    return out_file
