import os
import shutil
import subprocess

import xarray as xr
import yaml
from termcolor import cprint


def set_attributes(da, var):
    """Set NetCDF attributes for XArray object to values that LPJ-GUESS expects.

    Args:
        da: xarray.Dataarray object
        var: Variable name as it is defined in `options.yaml`.
    """
    attributes = yaml.load(open("options.yaml"))["nc_attributes"][var]
    for key in attributes:
        da.attrs[key] = attributes[key]


def set_metadata(trace_file):
    """Set NetCDF metadata of given file to CF standards for LPJ-GUESS.

    Args:
        trace_file: Full path to TraCE-21ka NetCDF file.

    Raises:
        FileNotFoundError: If `trace_file` does not exist.
        RuntimeError: Executable `ncatted` is not in the PATH
    """
    if not os.path.isfile(trace_file):
        raise FileNotFoundError(f"TraCE file doesn’t exist: '{trace_file}'")
    if shutil.which('ncatted') is None:
        raise RuntimeError("Executable `ncatted` not found.")
    cprint(f"Setting metadata for file '{trace_file}'.", 'yellow')
    attributes = yaml.load(open("options.yaml"))["nc_attributes"]
    ncatted_args = list()
    for var in attributes:
        with xr.open_dataset(trace_file, decode_times=False) as ds:
            if var not in ds:
                continue
        for key in attributes[var]:
            val = attributes[var][key]
            ncatted_args += ['--attribute', f'{key},{var},o,c,{val}']
    try:
        subprocess.run(['ncatted', '--overwrite'] + ncatted_args +
                       [trace_file], check=True)
    except Exception:
        if os.path.isfile(trace_file):
            cprint(f"Removing file '{trace_file}'.", 'red')
            os.remove(trace_file)
        raise
