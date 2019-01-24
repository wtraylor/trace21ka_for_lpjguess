import os

import xarray as xr
import yaml
from termcolor import cprint


def convert_time_unit(trace_file):
    """Convert kaBP time unit to TODO...

    Args:
        trace_file: File path to TraCE-21ka file with kaBP unit.

    Raises:
        FileNotFoundError: If `trace_file` does not exist.
    """
    if not os.path.isfile(trace_file):
        raise FileNotFoundError(f"Could not find TraCE file '{trace_file}'.")
    attrs = yaml.load(open('options.yaml'))['nc_attributes']['time']
    dataset = xr.open_dataset(trace_file)
    try:
        kaBP = - dataset.time.values
        years_BP = kaBP * 1000
        years_BC = years_BP - 1950
        years_since_20050_BC = 20050 - years_BC
        days_since_20050_BC = 365 * years_since_20050_BC
        dataset.time.values = days_since_20050_BC
        dataset.time.attrs['units'] = attrs['units']
        dataset.time.attrs['calendar'] = attrs['calendar']
        dataset.to_netcdf(trace_file, mode='w')
    except:
        cprint(f"Removing file '{trace_file}'.", 'red')
        os.remove(trace_file)
    finally:
        dataset.close()
