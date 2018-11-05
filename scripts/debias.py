#!/bin/python

# Usage: debias.py <input> <output>

import os
import sys
import xarray as xr

# Read command line argument.
if len(sys.argv) != 3:
    print("Usage: debias.py <input> <output>")
    sys.exit(1)
trace_file = sys.argv[1]
out_file = sys.argv[2]

print("debias.py: '%s' => '%s'" % (trace_file, out_file))

if not os.path.isfile(trace_file):
    print("debias.py: Input TraCE file does not exist: '%s'" % trace_file)
    sys.exit(1)

# The TraCE map as xarray Dataset.
trace = xr.open_dataset(trace_file)

# Find the variable in the TraCE file.
if 'TREFHT' in trace.data_vars:
    var = 'TREFHT'
elif 'PRECT' in trace.data_vars:
    var = 'PRECT'
else:
    print("debias.py: Could not find known variable in TraCE file: '%s'." %
          trace_file)
    sys.exit(1)

bias_file = "heap/bias_%s.nc" % var

if not os.path.isfile(bias_file):
    print("debias.py: Bias file does not exist: '%s'" % bias_file)
    sys.exit(1)

# The bias map as xarray Dataset.
bias = xr.open_dataarray(bias_file).load()

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
    print("debias.py: No bias correction defined for variable '%s'." % var)
    sys.exit(1)

if not os.path.isdir("heap/debiased"):
    os.mkdir("heap/debiased")

output.to_netcdf(out_file)
