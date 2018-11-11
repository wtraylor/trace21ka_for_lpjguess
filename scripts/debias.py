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
    # The mean number of wet days per month from the CRU dataset.
    cru_prec_std = xr.open_dataset("heap/cru_mean/wet_std.nc", decode_times=False)
    # Arbitrary number for missing values.
    NODATA = -9999
    # Create a numpy array of the same shape, but with missing values.
    wet_values = np.full_like(trace[var].values, NODATA, dtype='int32')
    # Create an
    months = range(12) * 
    for i, (month, days) in enumerate(zip(months, days_per_month)):
        mean_daily_prec = trace[var][i] / float(days)
        wet_values[i] = calc_wet_days(mean_daily_prec,
                                      cru_prec_std[month],
                                      days)


output.to_netcdf(out_file)
output.close()
