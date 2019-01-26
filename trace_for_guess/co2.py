import os

import xarray as xr
from termcolor import cprint

from trace_for_guess.skip import skip


def create_co2_file(trace_file, co2_file):
    """Create a CO₂ file for LPJ-GUESS.

    Args:
        trace_file: Path to TraCE file.
        co2_file: Output file.

    Raises:
        FileNotFoundError: `trace_file` does not exist.
    """
    if not os.path.isfile(trace_file):
        raise FileNotFoundError(f"Input file not found: '{trace_file}'")
    if skip(trace_file, co2_file):
        return
    try:
        with xr.open_dataset(trace_file, decode_times=False) as ds, \
                open(co2_file, 'w') as f:
            co2 = ds['co2vmr']
            for i in range(len(co2.values)):
                year = co2['time'].values[i]
                value = co2.values[i]
                f.write(f'{year}\t{value}\n')
    except Exception:
        if os.path.isfile(co2_file):
            cprint(f"Removing file '{co2_file}'.", 'red')
            os.remove(co2_file)
        raise
    assert(os.path.isfile(co2_file))
    cprint(f"Successfully created file: '{co2_file}'", 'green')
