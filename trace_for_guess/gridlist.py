import os

import xarray as xr
from termcolor import cprint

from trace_for_guess.skip import skip


def get_longitude(dataset):
    """Get longitude dimension from XArray dataset object."""
    for dim_name in ['lon', 'long', 'longitude']:
        if dim_name in dataset.coords:
            return dataset[dim_name]
    raise RuntimeError('Could not find longitude dimension in dataset.')


def get_latitude(dataset):
    """Get latitude dimension from XArray dataset object."""
    for dim_name in ['lat', 'latitude']:
        if dim_name in dataset.coords:
            return dataset[dim_name]
    raise RuntimeError('Could not find latitude dimension in dataset.')


def create_gridlist(netcdf_file, gridlist_file):
    """Create a gridlist file for LPJ-GUESS from a NetCDF file.

    Args:
        netcdf_file: Path to NetCDF input file.
        gridlist_file: Path to output file.

    Raises:
        FileNotFoundError: `netcdf_file` does not exist.
    """
    if not os.path.isfile(netcdf_file):
        raise FileNotFoundError(f"Input file doesn’t exist: '{netcdf_file}'")
    if skip(netcdf_file, gridlist_file):
        return
    try:
        with xr.open_dataset(netcdf_file, decode_times=False) as ds, \
                open(gridlist_file, 'w') as gridlist:
            lon_arr = get_longitude(ds).values
            lat_arr = get_latitude(ds).values
            for lon in lon_arr:
                for lat in lat_arr:
                    gridlist.write(f"{lon}\t{lat}\n")
    except Exception:
        cprint(f"Removing file '{gridlist_file}'.", 'red')
        os.remove(gridlist_file)
        raise
    assert(os.path.isfile(gridlist_file))
    cprint(f"Successfully created gridlist file '{gridlist_file}'.", 'green')
