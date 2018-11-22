#!/bin/python

# Usage: debias.py <input> <output>

from termcolor import cprint
import numpy as np
import os
import sys
import xarray as xr

# Name of this script file.
scriptfile = os.path.basename(__file__) + ": "

# Read command line argument.
if len(sys.argv) != 3:
    cprint("Usage: %s <input> <output>" % scriptfile + "red")
    sys.exit(1)
trace_file = sys.argv[1]
out_file = sys.argv[2]

cprint(scriptfile + "'%s' => '%s'" % (trace_file, out_file), "green")

if not os.path.isfile(trace_file):
    cprint(scriptfile + "Input TraCE file does not exist: '%s'" % trace_file,
           "red")
    sys.exit(1)

# The TraCE map as xarray Dataset.
trace = xr.open_dataset(trace_file, decode_times=False)

# Find the variable in the TraCE file.
if 'TREFHT' in trace.data_vars:
    var = 'TREFHT'
elif 'PRECT' in trace.data_vars:
    var = 'PRECT'
else:
    cprint(scriptfile + "Could not find known variable in TraCE file: '%s'." %
           trace_file, "red")
    sys.exit(1)

bias_file = "heap/bias_%s.nc" % var

if not os.path.isfile(bias_file):
    cprint(scriptfile + "Bias file does not exist: '%s'" % bias_file, "red")
    sys.exit(1)

# The bias map as xarray Dataset.
bias = xr.open_dataarray(bias_file, decode_times=False).load()

# How many years are in the monthly TraCE file?
years = len(trace[var]) // 12

# Repeat the monthly bias values for each year.
bias = xr.concat([bias]*years, dim='time')

# Overwrite the time dimension. If it does not match the TraCE file, the
# arithmetic operation does not work.
bias.time.values = trace.time.values

# Apply the bias to TraCE data.
if var == "TREFHT":
    output = trace[var] + bias
elif var == "PRECT":
    output = trace[var] * bias
else:
    cprint(scriptfile + "No bias correction defined for variable '%s'." % var,
           "red")
    sys.exit(1)

if not os.path.isdir("heap/debiased"):
    os.mkdir("heap/debiased")

# Calculate wet days.
if var == "PRECT":
    # The mean standard deviation of daily precipitation within each month.
    # This dataset has 12 values (one for each month) per grid cell.
    cru_prec_std = xr.open_dataset("heap/crujra/monthly_std_regrid.nc",
                                   decode_times=False)
    # Arbitrary number for missing values.
    NODATA = -9999
    # Create a numpy array of the same shape, but with missing values.
    wet_values = np.full_like(trace[var].values, NODATA, dtype='int32')
    # Create an array that holds the month number (0 to 11) for each index in
    # the original TraCE time dimension.
    months_array = range(12) * (len(trace['time']) // 12)
    # Do the same for the number of days within each month.
    days_per_month = [31,28,31,30,31,30,31,31,30,31,30,31]
    days_per_month_array = days_per_month  * (len(trace['time']) // 12)
    for i, (month, days) in enumerate(zip(months_array, days_per_month_array)):
        mean_daily_prec = trace[var][i] / float(days)
        wet_values[i] = calc_wet_days(mean_daily_prec,
                                      cru_prec_std[month],
                                      days)
    set_attributes(wet_values, 
    wet_values.attrs['standard_name'] = "number_of_days_with_lwe_thickness_of_precipitation_amount_above_threshold"
    wet_values.attrs['long_name'] = "wet_days"
    wet_values.attrs['units'] = "count"
    wet_values.attrs['_FillValue'] = NODATA
    wet_values.attrs['missing_value'] = NODATA
    trace['wet'] = wet_values


output.to_netcdf(out_file)
output.close()
