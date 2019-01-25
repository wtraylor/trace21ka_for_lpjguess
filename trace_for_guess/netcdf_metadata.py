import os
import xarray as xr
import subprocess

import shutil
import yaml


def set_attributes(da, var):
    """Set NetCDF attributes for XArray object to values that LPJ-GUESS expects.

    Args:
        da: xarray.Dataarray object
        var: Variable name as it is defined in `options.yaml`.
    """
    attributes = yaml.load(open("options.yaml"))["nc_attributes"][var]
    for key in attributes:
        da.attrs[key] = attributes[key]


def set_metadata(trace_file, trace_var):
    """Set NetCDF metadata of given file to CF standards for LPJ-GUESS.

    Args:
        trace_file: Full path to TraCE-21ka NetCDF file.
        trace_var: The TraCE variable in the file.

    Raises:
        FileNotFoundError: If `trace_file` does not exist.
        RuntimeError: Executable `ncatted` is not in the PATH
    """
    if not os.path.isfile(trace_file):
        raise FileNotFoundError(f"TraCE file doesn’t exist: '{trace_file}'")
    if shutil.which('ncatted') is None:
        raise RuntimeError("Executable `ncatted` not found.")
    attributes = yaml.load(open("options.yaml"))["nc_attributes"][trace_var]
    ncatted_args = list()
    for (var, a) in attributes:
        with xr.open_dataset(f, decode_times=False) as ds:
            if var not in ds:
                continue
        for (key, val) in attrs:
            ncatted_args += ['--attribute', f'{key},{var},o,c,{val}']
    subprocess.run(['ncatted', '--overwrite'] + ncatted_args
                    + [trace_file], check=True)
