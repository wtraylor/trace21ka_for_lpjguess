#!/bin/python

import os
import subprocess
import sys
import yaml

# Arguments:
# 1) Input file
# 2) Output file (will be overwritten!)

if len(sys.argv) != 3:
    print("Please provide exactly two command line arguments.")
    sys.exit(1)

in_file = sys.argv[1]
out_file = sys.argv[2]

if not os.path.isfile(in_file):
    print("Input file does not exist.")
    sys.exit(1)


region = yaml.load(open("options.yaml"))["region"]
lon = region["lon"]
lat = region["lat"]

# TODO: Check if region is valid.

print("Cropping file '%s'..." % in_file)
status = subprocess.run(["ncks",
                         "--overwrite",
                         "--dimension", "lon,%.2f,%.2f" % (lon[0], lon[1]),
                         "--dimension", "lat,%.2f,%.2f" % (lat[0], lat[1]),
                         in_file,
                         out_file]).returncode

if status != 0:
    print("Cropping with `ncks` failed: Bad return code.")
    print("Input file:", in_file)
    print("Output file:", out_file)
    sys.exit(1)

if not os.path.isfile(out_file):
    print("Cropping with `ncks` failed: No output file created.")
    print("Input file:", in_file)
    print("Output file:", out_file)
    sys.exit(1)
