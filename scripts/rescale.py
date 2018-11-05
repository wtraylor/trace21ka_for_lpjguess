#!/bin/python

import os
import subprocess
import sys
import yaml

regrid_alg = yaml.load(open("options.yaml"))["regrid_algorithm"]

if len(sys.argv) != 3:
    print("Please provide exacty two command line arguments.")
    print("rescale.py <input file> <output file>")
    sys.exit(1)
in_file = sys.argv[1]
out_file = sys.argv[2]

if not os.path.isfile(in_file):
    print("First argument is not a file: '%s'" % in_file)
    sys.exit(1)

# Template grid.
grid_templ = "cruncep/temperature.nc"

print("Regridding: '%s' => '%s'" % (in_file, out_file))

status = subprocess.run(["ncremap",
                         "--algorithm=%s" % regrid_alg,
                         "--template_file=%s" % grid_templ,
                         "--input_file=%s" % in_file,
                         "--output_file=%s" % out_file])

if not os.path.isfile(out_file):
    print("Regridding with `ncremap` failed: No output file created.")
    print("Input file:", in_file)
    print("Output file:", out_file)
    sys.exit(1)
