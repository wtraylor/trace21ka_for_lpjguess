import os
import shutil
import subprocess

from termcolor import cprint
import yaml

from trace_for_guess.skip import skip


def compress_and_chunk(in_file, out_file):
    """Compress and chunk a NetCDF file using NCO using lossless deflation.

    We save in the "netcdf4" format because only then the chunking will be
    supported.

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
    opts = yaml.load(open('options.yaml'))
    compression_level = opts['compression_level']
    chunk_lon = opts['chunks']['lon']
    chunk_lat = opts['chunks']['lat']
    chunk_time = opts['chunks']['time']
    chunk_cache = opts['chunks']['cache']
    cprint(f"Compressing and chunking file '{in_file}'...", 'yellow')
    try:
        subprocess.run(['ncks',
                        '--deflate', str(compression_level),
                        '--chunk_dimension', f'lon,{chunk_lon}',
                        '--chunk_dimension', f'lat,{chunk_lat}',
                        '--chunk_dimension', f'time,{chunk_time}',
                        '--chunk_cache', str(chunk_cache),
                        '--fl_fmt', 'netcdf4',
                        in_file, out_file], check=True)
    except Exception:
        if os.path.isfile(out_file):
            cprint(f"Removing file '{out_file}'.", 'red')
            os.remove(out_file)
        raise
    assert(os.path.isfile(out_file))
    cprint(f"Successfully created file: '{out_file}'", 'green')
    return out_file
