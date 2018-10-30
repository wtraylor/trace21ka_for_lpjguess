#!/bin/python

import os
import sys
import xarray as xr
import yaml

def drop_superfluous_trace_vars(data):
    """Drop all unneeded data variables from a TraCE-21ka xarray dataset."""
    return data.drop(["P0", "co2vmr", "gw", "hyai", "date", "date_written",
                     "datesec", "hyai", "hyam", "hybi", "hybm", "mdt",
                     "nbdate", "nbsec", "ndbase", "ndcur", "nlon", "nsbase",
                     "nscur", "nsteph", "ntrk", "ntrm", "ntrn", "time_written",
                     "wnummax"])

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
    data = drop_superfluous_trace_vars(data) # TODO: Do we need this?
    # Repeat the months (assuming the dataset begins with January).
    year_count = len(data["time"]) // 12
    month_dim = month_numbers * year_count
    # Overwrite the time dimension with months.
    data["time"].values = month_dim
    # Create mean monthly temperatures over the whole time span for each grid
    # cell.
    data = data.groupby('time').mean('time')
    return data

# Find relevant TraCE files of the modern time in a directory.
# The file names are defined in the YAML options.

if not os.path.exists("trace_orig"):
    print("Directory 'trace_orig' doesn’t seem to exist.")
    sys.exit(1)

# Retrieve directory to dump temporary files.
heap = os.environ.get("HEAP")
if not heap:
    print("Heap directory not provided in environment variable `HEAP`.")
    sys.exit(1)
heap = os.path.abspath(heap)
if not os.path.exists(heap):
    print("Creating heap directory: %s" % heap)
    os.mkdir(heap)

# Check if all original TraCE files are present.
files = opts["modern_trace_files"]
for f in files:
    if files[f] not in os.listdir("trace_orig"):
        print("Couldn’t find TraCE file with modern monthly data for "
              "variable %s:\n %s" % (f, files[f]))
        sys.exit(1)
    else:
        files[f] = os.path.join("trace_orig", files[f])

# Calculate averages and write new NetCDF files to heap directory.
for f in files:
    print("Aggregating monthly averages from file '%s'." % files[f])
    dataset = get_monthly_means(files[f])
    out_file = "modern_trace_" + f + ".nc"
    out_file = os.path.join(heap, out_file)
    print("Writing file '%s'." % out_file)
    dataset.to_netcdf(out_file)

