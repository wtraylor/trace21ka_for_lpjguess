import os
import warnings

import numpy as np
import scipy.stats
import xarray as xr
import yaml
from termcolor import cprint

from trace_for_guess.netcdf_metadata import set_attributes
from trace_for_guess.skip import skip

# Arbitrary number for missing values.
NODATA = 999999999


def get_gamma_cdf(x, xmean, xstd):
    """Calculate cumulative density function of gamma distribution.

    Args:
        x: TODO
        xmean: Monthly mean precipitation.
        xstd: Standard deviation of precipitation.

    Returns:
        Cumulative density of gamma distribution.
    """
    shape = np.power(xmean, 2) / np.power(xstd, 2)
    rate = np.power(xstd, 2) / xmean
    # scipy raises this “RuntimeWarning: invalid value encountered in greater”
    # I don’t know why so I just suppress it.
    with warnings.catch_warnings():
        warnings.simplefilter('ignore')
        rv = scipy.stats.gamma(shape, scale=rate)
        return rv.cdf(x)


def calc_wet_days(trace_prec, cru_std, days, threshold):
    """Calculate wet days per month.

    Arguments:
        trace_prec: Array with one month’s mean daily precipitation [mm/day]
            from the TraCE dataset for all grid cells.
        cru_std: Array with standard deviation (day-to-day variability) of this
            month’s precipitation from the CRU dataset.
        days: Number of days for this month.
        threshold: Minimum precipitation [mm/day] to count a day as “wet”.

    Returns:
        Array with number of wet days in the month for the TraCE data.
    """
    # Catch potential zero divide.
    almost_zero = 0.00000001
    cru_std = np.where(cru_std == 0, almost_zero, cru_std)
    trace_prec = np.where(trace_prec == 0, almost_zero, trace_prec)

    # Get cumulative density function: The probability that it stays dry, in
    # one particular day in the month.
    cdf = get_gamma_cdf(x=threshold, xmean=trace_prec, xstd=cru_std)
    # This probability is inversed to get the probability for rain and then
    # multiplied by the number of days in the month in order to get the number
    # of rain days in the month.
    wet_days = (1.0 - cdf) * days
    # Number of wet days is an integer value, so we round up the float number.
    wet_days = np.ceil(wet_days)
    wet_days = np.nan_to_num(wet_days)
    # Make sure that number of wet days does not exceed total number of days.
    return np.where(wet_days > days, days, wet_days)


def get_wet_days_array(prect, prec_std):
    """Add a variable 'wet_days' to monthly precipitation TraCE dataset.

    Args:
        prect: xarray dataarray of a PRECT TraCE file with monthly
            precipitation.
        prec_std: xarray dataarray with monthly standard deviation of daily
            modern precipitation. The dataset has 12 values (one for each
            month) per grid cell.

    Returns:

    """
    precip_threshold = yaml.load(open('options.yaml'))['precip_threshold']
    # Create a numpy array of the same shape, but with missing values.
    wet_values = np.full_like(prect.values, NODATA, dtype='int32')
    # Create an array that holds the month number (0 to 11) for each index in
    # the original TraCE time dimension.
    months_array = [m for m in range(12)] * (len(prect['time']) // 12)
    # Do the same for the number of days within each month.
    days_per_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days_per_month_array = days_per_month * (len(prect['time']) // 12)
    assert(len(days_per_month_array) == len(prect))
    # Iterate over every month `t` (“time step”) in the transient time series.
    for t, (month, days) in enumerate(zip(months_array, days_per_month_array)):
        mean_daily_prec = prect[t] / float(days)
        wet_values[t] = calc_wet_days(mean_daily_prec, prec_std[month], days,
                                      precip_threshold)
    return wet_values


def create_wet_days_file(prect_file, prec_std_file, out_file):
    """Calculate wet days for TraCE precipitation.

    Args:
        prect_file: Path to original TraCE-21ka NetCDF file with total
            precipitation (PRECT).
        prec_std_file: File with day-to-day standard deviation of
            precipitation for each month. Only relevant for calculating wet
            days.
        out_file: Output NetCDF file.

    Returns:
        The newly created NetCDF file `out_file`.

    Raises:
        FileNotFoundError: `prect_file` or `prec_std_file` not found.
        ValueError: The `prect_file` does not contain the 'PRECT' variable.
    """
    if not os.path.isfile(prect_file):
        raise FileNotFoundError(f"Input file does not exist: '{prect_file}'")
    if not os.path.isfile(prec_std_file):
        raise FileNotFoundError("File with precipitation standard deviation "
                                f"does not exist: '{prec_std_file}'")
    if skip([prect_file, prec_std_file], out_file):
        return out_file
    cprint(f"Adding wet days for precipitation file '{prect_file}'...",
           'yellow')
    out_dir = os.path.dirname(out_file)
    if not os.path.isdir(out_dir):
        cprint(f"Directory '{out_dir}' does not exist yet. I will create it.",
               'yellow')
        os.makedirs(out_dir)
    try:
        with xr.open_dataarray(prec_std_file, decode_times=False) as std, \
                xr.open_dataset(prect_file, decode_times=False) as trace:
            if 'PRECT' not in trace:
                raise ValueError("File does not contain total precipitation"
                                 f"variable 'PRECT': '{prect_file}'.")
            da = xr.full_like(trace['PRECT'], NODATA, dtype='int32')
            da.values = get_wet_days_array(trace['PRECT'], std)
            set_attributes(da, "wet_days")
            da.attrs['_FillValue'] = NODATA
            da.attrs['missing_value'] = NODATA
            trace['wet'] = da
            trace.to_netcdf(out_file, mode='w', engine='netcdf4')
    except Exception:
        if os.path.isfile(out_file):
            cprint(f"Removing file '{out_file}'.", 'red')
            os.remove(out_file)
        raise
    assert os.path.isfile(out_file), 'No output created.'
    cprint(f"Successfully created '{out_file}'.", 'green')
    return out_file
