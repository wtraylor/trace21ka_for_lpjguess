# SPDX-FileCopyrightText: 2021 Wolfgang Traylor <wolfgang.traylor@senckenberg.de>
#
# SPDX-License-Identifier: MIT

import os

import numpy as np
import xarray as xr
from termcolor import cprint

from trace_for_guess.skip import skip


def precip_flux_to_mm_per_month(data_array):
    """Convert precipitation from kg/m²/s to mm/month.

    See the README.md for a detailed explanation of the formula.
    """
    # TODO Take month lengths into account!
    days_per_month = 30
    seconds_per_month = days_per_month * 24 * 60 * 60
    return data_array * seconds_per_month


def celsius_to_kelvin(x):
    """Convert from degrees Celsius to Kelvin."""
    return x + 273.15


def calculate_bias(trace_file, trace_var, cru_file, cru_var, bias_file):
    """Create a file with the monthly bias of TraCE compared to the CRUNCEP data.

    Each of the input files should contain only 12 values per grid cell
    (one average per month).

    Args:
        trace_file: The TraCE-21ka NetCDF file with modern monthly averages.
        trace_var: NetCDF variable in the TraCE file.
        cru_file: The CRU NetCDF file with modern monthly averages.
        cru_var: NetCDF variable in the CRU file.
        bias_file: Path to output file (will not be overwritten).

    Returns:
        Path to output file (equals `bias_file`).

    Raises:
        FileNotFoundError: The file `trace_file` or `cru_file` wasn’t found.
        NotImplementedError: The variable in the TraCE file is not
            implemented.
    """
    if not os.path.isfile(trace_file):
        raise FileNotFoundError(
            "TraCE-21ka mean file doesn’t exist: '%s'" % trace_file)
    if not os.path.isfile(cru_file):
        raise FileNotFoundError("CRU mean file doesn’t exist: '%s'" % cru_file)
    if skip([trace_file, cru_file], bias_file):
        return bias_file
    cprint('Calculating bias:', 'yellow')
    cprint(f"'{trace_file}' x '{cru_file}' -> '{bias_file}'", 'yellow')
    # Open and load the files completely. They need to be in the RAM for
    # calculation.
    trace = xr.open_dataset(trace_file, decode_times=False).load()
    cru = xr.open_dataset(cru_file, decode_times=False).load()
    try:
        # The values of the 'time' dimensions of the CRU and the TraCE dataset
        # must match in order to perform calculation. So we just overwrite the
        # values with 0 to 11 as the month numbers, assuming that the CRU
        # record also starts with January.
        cru["time"].values = [i for i in range(12)]
        # Rename the variable in the CRU file to the TraCE variable name.
        cru = cru.rename({cru_var: trace_var})
        if trace_var == "TREFHT":
            bias = trace[trace_var] - celsius_to_kelvin(cru[trace_var])
        elif trace_var == "PRECT":
            # The CRU precipitation is in mm/month.
            # The TraCE precipitation is in kg/m²/s (already converted!).
            # We convert to high numbers to do the division in order to prevent
            # any floating point precision errors.
            trace[trace_var] = precip_flux_to_mm_per_month(trace[trace_var])
            # Catch potential division by zero.
            almost_zero = 1  # [mm/month]
            c = cru[trace_var]
            c = np.where(c == 0, almost_zero, c)
            bias = trace[trace_var] / c
        elif trace_var == "CLDTOT":
            # The CRU data needs to be divided by 100 because it comes in
            # percent, not fraction.
            bias = np.log(trace[trace_var]) / np.log(cru[trace_var] / 100.0)
        else:
            raise NotImplementedError("Arithmetic operation not defined for"
                                      "variable '%s'." % trace_var)
        bias.to_netcdf(bias_file, mode='w', engine='netcdf4')
        bias.close()
    except Exception:
        if os.path.isfile(bias_file):
            cprint(f"Removing file '{bias_file}'.", 'red')
            bias.close()
            os.remove(bias_file)
        raise
    finally:
        trace.close()
        cru.close()
    assert os.path.isfile(bias_file)
    cprint(f"Successfully created '{bias_file}'.", 'green')
    return bias_file
