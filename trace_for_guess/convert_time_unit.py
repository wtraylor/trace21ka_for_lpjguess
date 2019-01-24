import os

import xarray as xr
import yaml
from termcolor import cprint


def convert_time_unit(trace_file, out_file):
    """Convert kaBP time unit to TODO...

    Args:
        trace_file: File path to TraCE-21ka file with kaBP unit.
        out_file: Output file with converted time unit.

    Raises:
        FileNotFoundError: If `trace_file` does not exist.

    Returns:
        Path to output file, same as parameter `out_file`.
    """
    if not os.path.isfile(trace_file):
        raise FileNotFoundError(f"Could not find TraCE file '{trace_file}'.")
    if os.path.isfile(out_file):
        cprint(f"Skipping: '{out_file}'", 'cyan')
        return out_file
    out_dir = os.path.dirname(out_file)
    if not os.path.isdir(out_dir):
        cprint(f"Directory '{out_dir}' does not exist yet. I will create it.",
            'yellow')
        os.makedirs(out_dir)
    cprint(f"Converting time unit of TraCE file '{trace_file}'.", 'yellow')
    attrs = yaml.load(open('options.yaml'))['nc_attributes']['time']
    try:
        with xr.open_dataset(trace_file) as dataset:
            kaBP = - dataset.time.values
            years_BP = kaBP * 1000
            years_BC = years_BP - 1950
            years_since_20050_BC = 20050 - years_BC
            days_since_20050_BC = 365 * years_since_20050_BC
            dataset.time.values = days_since_20050_BC
            dataset.time.attrs['units'] = attrs['units']
            dataset.time.attrs['calendar'] = attrs['calendar']
            dataset.to_netcdf(out_file, mode='w')
    except:
        if os.path.isfile(out_file):
            cprint(f"Removing file '{trace_file}'.", 'red')
            os.remove(out_file)
    assert(os.path.isfile(out_file))
    cprint(f"Created TraCE file with converted time unit in
    return out_file
