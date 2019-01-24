import os

import numpy as np
import xarray as xr
from scipy.stats import gamma
from termcolor import cprint

from trace_for_guess.cf_attributes import set_attributes


def get_gamma_cdf(x, xmean, xstd):
    """Calculate cumulative density function of gamma distribution.

    Args:
        x: TODO
        xmean: Monthly mean precipitation.
        xstd: Standard deviation of precipitation."""
    shape = (xmean * xmean) / (xstd * xstd)  # α
    rate = xstd * xstd / xmean  # β

    rv = gamma(shape, scale=rate)
    return rv.cdf(x)


def calc_wet_days(trace_prec, cru_std, days):
    """Calculate wet days per month.

    Arguments:
        trace_prec: Array with one month’s mean daily precipitation [mm/day]
            from the TraCE dataset for all grid cells.
        cru_std: Array with standard deviation (day-to-day variability) of this
            month’s precipitation from the CRU dataset.
        days: Number of days for this month.
    Returns:
        Array with number of wet days in the month for the TraCE data.
    """
    precip_threshold = 0.1  # [mm/day], constant

    # Catch potential zero divide.
    cru_std = np.where(cru_std == 0, 0.0000000000001, cru_std)

    # Get cumulative density function: The probability that it stays dry, in
    # one particular day in the month.
    cdf = get_gamma_cdf(precip_threshold, trace_prec, cru_std)
    # This probability is inversed to get the probability for rain and then
    # multiplied by the number of days in the month in order to get  the number
    # of rain days in the month.
    wet_days = (1.0 - cdf) * days
    # Number of wet days is an integer value, so we round up the float number.
    wet_days = np.ceil(wet_days)
    # Make sure that number of wet days does not exceed total number of days.
    return np.where(wet_days > days, days, wet_days)


def add_wet_days_to_dataset(trace, prec_std):
    """Add a variable 'wet_days' to monthly precipitation TraCE dataset.

    Args:
        trace: xarray dataset of TraCE file with monthly precipitation.
        prec_std: xarray dataset with monthly standard deviation of daily
            modern precipitation. The dataset has 12 values (one for each
            month) per grid cell.
    """
    # Arbitrary number for missing values.
    NODATA = -9999
    # Create a numpy array of the same shape, but with missing values.
    wet_values = np.full_like(trace['PRECT'].values, NODATA, dtype='int32')
    # Create an array that holds the month number (0 to 11) for each index in
    # the original TraCE time dimension.
    months_array = range(12) * (len(trace['time']) // 12)
    # Do the same for the number of days within each month.
    days_per_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days_per_month_array = days_per_month * (len(trace['time']) // 12)
    for i, (month, days) in enumerate(zip(months_array, days_per_month_array)):
        mean_daily_prec = trace['PRECT'][i] / float(days)
        wet_values[i] = calc_wet_days(mean_daily_prec,
                                      prec_std[month],
                                      days)
    set_attributes(wet_values, "wet_days")
    wet_values.attrs['_FillValue'] = NODATA
    wet_values.attrs['missing_value'] = NODATA
    trace['wet'] = wet_values


def add_wet_days_to_file(filename, prec_std_file):
    """Add wet days variable to TraCE precipitation.

    Args:
        filename: Path to original TraCE-21ka NetCDF file with total
            precipitation (PRECT).
        prec_std_file: File with day-to-day standard deviation of
            precipitation for each month. Only relevant for calculating wet
            days.
    Raises:
        FileNotFoundError: `filename` or `prec_std_file` not found.
    """
    if not os.path.isfile(filename):
        raise FileNotFoundError(f"Input file does not exist: '{filename}'")
    if not os.path.isfile(prec_std_file):
        raise FileNotFoundError("File with precipitation standard deviation "
                                f"does not exist: '{prec_std_file}'")
    cprint(f"Adding wet days to precipitation file '{filename}'.", 'yellow')
    try:
        with xr.open_dataset(prec_std_file, decode_times=False) as std, \
                xr.open_dataset(filename, decode_times=False) as trace:
            add_wet_days_to_dataset(trace, std)
            trace.to_netcdf(filename)
    except:
        if os.file.isfile(filename):
            cprint(f"Removing file '{filename}'.", 'red')
            os.remove(filename)
        raise
    assert os.path.isfile(filename), 'No output created.'
