from termcolor import cprint
import os
import sys
import xarray as xr

def drop_superfluous_trace_vars(data):
    """Drop all unneeded data variables from a TraCE-21ka xarray dataset."""
    return data.drop(["P0", "co2vmr", "gw", "hyai", "date", "date_written",
                      "datesec", "hyai", "hyam", "hybi", "hybm", "mdt",
                      "nbdate", "nbsec", "ndbase", "ndcur", "nlon", "nsbase",
                      "nscur", "nsteph", "ntrk", "ntrm", "ntrn",
                      "time_written", "wnummax"])


def get_monthly_means(trace_file):
    """
    Aggregate TraCE-21ka file over time to have only 12 data points per cell.

    Args:
        trace_file: File path of the TraCE-21ka NetCDF file.

    Returns:
        A xarray.Dataset object of the file.
    """
    data = xr.open_dataset(trace_file, decode_times=False)
    # Create list with numbers from 0 (January) to 12 (December).
    month_numbers = [i for i in range(12)]
    data = drop_superfluous_trace_vars(data)  # TODO: Do we need this?
    # Repeat the months (assuming the dataset begins with January).
    year_count = len(data["time"]) // 12
    month_dim = month_numbers * year_count
    # Overwrite the time dimension with months.
    data["time"].values = month_dim
    # Create mean monthly temperatures over the whole time span for each grid
    # cell.
    data = data.groupby('time').mean('time')
    return data


def aggregate_modern_trace(target, source, env):
    """
    Calculate 12 monthly means from monthly values from TraCE file over time.

    This function is designed as a SCons action to be executed by a
    SCons builder.
    """
    # Calculate averages and write new NetCDF files to heap directory.
    cprint("Aggregating monthly averages from file '%s'." % source,
           "green")
    dataset = get_monthly_means(trace_file=source)
    cprint("Writing file '%s'." % target, "green")
    dataset.to_netcdf(target)
    dataset.close()
    return None  # Success.
