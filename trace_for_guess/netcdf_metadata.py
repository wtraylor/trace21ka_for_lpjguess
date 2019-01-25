import os

import yaml


def set_attributes(da, var):
    """Set NetCDF attributes for XArray object to values that LPJ-GUESS expects.

    Args:
        da: xarray.Dataarray object
        var: Variable name as it is defined in `options.yaml`.
    """
    attributes = yaml.load(open("options.yaml"))["nc_attributes"][var]
    for (key, val) in attributes:
        da.attrs[key] = val


def set_metadata(trace_file, var):
    """Set NetCDF metadata of given file to CF standards for LPJ-GUESS.

    Args:
        trace_file: Full path to TraCE-21ka NetCDF file.
        var: The TraCE variable in the file.

    Raises:
        FileNotFoundError: If `trace_file` does not exist.
    """
    if not os.path.isfile(trace_file):
        raise FileNotFoundError(f"TraCE file doesn’t exist: '{trace_file}'")
