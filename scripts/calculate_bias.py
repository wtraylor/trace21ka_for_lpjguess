#!/bin/python

import os
import sys
import xarray as xr
import yaml

# The first (and only) command line argument is the TraCE variable.
if len(sys.argv) != 2:
    print("Please provide the TraCE variable as one command line argument.")
    sys.exit(1)
var = sys.argv[1]

# Construct the TraCE input file name.
trace_file = os.path.join("heap", "modern_trace_%s_regrid.nc" % var)
if not os.path.exists(trace_file):
    print("Input file does not exist: %s" % trace_file)
    sys.exit(1)

# Open and load the file completely. It needs to be in the RAM for calculation.
trace = xr.open_dataset(trace_file).load()

cru_file = "heap/cru_regrid/%s.nc" % var

if not os.path.exists(cru_file):
    print("CRUNCEP file is missing: %s" % cru_file)
    sys.exit(1)

# The CRU file needs to be loaded immediately to RAM in order to perform
# arithmetic operations with the dataeset.
cru = xr.open_dataset(cru_file).load()

# The values of the 'time' dimensions of the CRU and the TraCE dataset must
# match in order to perform calculation. So we just overwrite the values with
# 0 to 11 as the month numbers, assuming that the CRUNCEP record also starts
# with January.
cru["time"].values = [i for i in range(12)]

# Rename the variable in the CRU file to the TraCE variable name.
cru_vars = yaml.load(open("options.yaml"))["cru_vars"]
if var not in cru_vars:
    print("Variable '%s' is not in 'cru_vars' in options.yaml." % var)
    sys.exit(1)
cru = cru.rename({cru_vars[var]: var})

if var == "TREFHT":
    bias = trace[var] - cru[var]
elif var == "PRECT":
    # TODO Rename precipitation variable
    bias = trace[var] / cru[var]
else:
    print("Arithmetic operation not defined for variable '%s'." % var)
    sys.exit(1)

bias_file = os.path.join(heap, "bias_%s.nc" % var)
print("Saving bias map to file '%s'." % bias_file)
bias.to_netcdf(bias_file, mode='w')
