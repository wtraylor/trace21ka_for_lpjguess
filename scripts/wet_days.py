#!/bin/python

import numpy as np
from scipy.stats import gamma


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


def calc_wetdays(trace_prec, cru_std, days):
    """Calculate wet days per month.

    Arguments:
        trace_prec: Array of monthly mean precipitation [mm/month] from the
            TraCE dataset.
        cru_std: Standard deviation (day-to-day variability) of monthly
            precipitation from the CRU dataset.
        days: Number of days for each month.
    Returns:
        An array of the same dimensions like `trace_prec` containing the wet
        days per month.
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
