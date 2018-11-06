#!/bin/python

# The one and only command line argument is the TraCE variable.

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

# Read command line argument: the TraCE variable.
if len(sys.argv) != 2:
    print("Please provide the TraCE variable as one command line argument.")
    sys.exit(1)
var = sys.argv[1]

# Find relevant TraCE files of the modern time in a directory.

if not os.path.exists("trace_orig"):
    print("Directory 'trace_orig' doesn’t seem to exist.")
    sys.exit(1)

# Compose file name of modern TraCE data.
file_name = "trace.36.400BP-1990CE.cam2.h0.%s.2160101-2204012.nc" % var
file_name = os.path.abspath(os.path.join("trace_orig", file_name))
if not os.path.isfile(file_name):
    print("Couldn’t find TraCE file with modern monthly data for "
          "variable %s:\n '%s'" % (var, file_name))
    sys.exit(1)

# Calculate averages and write new NetCDF files to heap directory.
print("Aggregating monthly averages from file '%s'." % file_name)
dataset = get_monthly_means(file_name)
out_file = "modern_trace_" + var + ".nc"
out_file = os.path.join("heap", out_file)
print("Writing file '%s'." % out_file)
dataset.to_netcdf(out_file)
dataset.close()
