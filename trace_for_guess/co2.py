import os

import xarray as xr
from termcolor import cprint

from trace_for_guess.skip import skip


def create_co2_file(trace_files, co2_file):
    """Create a CO₂ file for LPJ-GUESS from TraCE-21ka files.

    TODO: The `year` column must be continuously incrementing calendar years.

    Args:
        trace_files: A list with contiguous TraCE-21ka files.
        co2_file: Output file.

    Raises:
        FileNotFoundError: A file in `trace_files` does not exist.
    """
    for f in trace_files:
        if not os.path.isfile(f):
            raise FileNotFoundError(f"Input file not found: '{f}'")
    if skip(trace_files, co2_file):
        return
    try:
        with open(co2_file, 'w') as out_file:
            for f in trace_files:
                with xr.open_dataset(trace_file, decode_times=False) as ds:
                    co2 = ds['co2vmr']
                    for i in range(len(co2.values)):
                        year = co2['time'].values[i]
                        value = co2.values[i]
                        out_file.write(f'{year}\t{value}\n')
    except Exception:
        if os.path.isfile(co2_file):
            cprint(f"Removing file '{co2_file}'.", 'red')
            os.remove(co2_file)
        raise
    assert(os.path.isfile(co2_file))
    cprint(f"Successfully created file: '{co2_file}'", 'green')
