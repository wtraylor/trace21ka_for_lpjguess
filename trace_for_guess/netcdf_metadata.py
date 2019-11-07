import os
import shutil
import subprocess

import xarray as xr
import yaml
from termcolor import cprint


def get_metadata_from_trace_file(trace_file):
    """Get time range and variable from given TraCE file.

    Args:
        trace_file: An existing TraCE NetCDF file.

    Returns:
        A dictionary with the header information of interest: first_year,
        last_year, variable

    Raises:
        FileNotFoundError: If `trace_file` does not exist.
        RuntimeError: `cdo` command is not in the PATH.
    """
    if not os.path.isfile(trace_file):
        raise FileNotFoundError(f"Could not find TraCE file '{trace_file}'.")
    if not shutil.which('cdo'):
        raise RuntimeError('`cdo` command is not in the PATH.')
    # Get time range:
    stdout = subprocess.run(
        ['cdo', 'showyear', '-select,timestep=1,-1', trace_file],
        check=True, capture_output=True, encoding='utf-8'
    ).stdout
    time_range = [int(s) for s in stdout.split()]
    assert len(time_range) == 2, f'file={trace_file}, stdout={stdout}'
    del stdout
    return {'first_year': int(time_range[0]),
            'last_year': int(time_range[1])}


def get_metadata_from_trace_files(trace_filelist):
    """Get time range and variable from a list of TraCE files.

    Args:
        trace_file: An existing TraCE NetCDF file.

    Returns:
        A dictionary with the header information of interest: first_year,
        last_year, variable

    Raises:
        FileNotFoundError: If a file in `trace_filelist` doesn’t exist.
        ValueError: If the variables of the files differ.
    """
    var = str()
    first_year = 9999999999999999999
    last_year = -9999999999999999999
    for f in trace_filelist:
        if not os.path.isfile(f):
            raise FileNotFoundError(f"Could not find TraCE file '{f}'.")
        metadata = get_metadata_from_trace_file(f)
        first_year = min(first_year, metadata['first_year'])
        last_year = max(last_year, metadata['last_year'])
        v = metadata['variable']
        if not var:
            var = v
        elif var != v:
            raise ValueError(
                f"The variable in file '{f}' is '{v}'. This is different from "
                f"the other files, which have variable '{var}'."
            )
    return {'first_year': first_year,
            'last_year': last_year,
            'variable': var}


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
