from termcolor import cprint

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


def aggregate_modern_trace(trace_file, out_file):
    """Calculate 12 monthly means from values from TraCE file over time.

    Args:
        trace_file: Path to original TraCE-21ka NetCDF file.
        out_file: Path to output file (will be overwritten).

    Raises:
        FileNotFoundError: The file `trace_file` wasn’t found.
    """
    cprint("Aggregating monthly averages from file '%s'." % trace_file,
           "green")
    if not os.path.isfile(trace_file):
        raise FileNotFoundError("Input file doesn’t exist: '%s'" % trace_file)
    dataset = get_monthly_means(trace_file)
    cprint("Writing file '%s'." % out_file, "green")
    dataset.to_netcdf(out_file)
    dataset.close()
