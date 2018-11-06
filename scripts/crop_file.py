#!/bin/python

from termcolor import cprint
import os
import subprocess
import sys
import yaml

# Arguments:
# 1) Input file
# 2) Output file (will be overwritten!)

if len(sys.argv) != 3:
    cprint("Please provide exactly two command line arguments.", "red")
    sys.exit(1)

in_file = sys.argv[1]
out_file = sys.argv[2]

if not os.path.isfile(in_file):
    cprint("Input file does not exist.", "red")
    sys.exit(1)


region = yaml.load(open("options.yaml"))["region"]
lon = region["lon"]
lat = region["lat"]

# TODO: Check if region is valid.

cprint("Cropping file '%s'..." % in_file, "green")
status = subprocess.run(["ncks",
                         "--overwrite",
                         "--dimension", "lon,%.2f,%.2f" % (lon[0], lon[1]),
                         "--dimension", "lat,%.2f,%.2f" % (lat[0], lat[1]),
                         in_file,
                         out_file]).returncode

if status != 0:
    cprint("Cropping with `ncks` failed: Bad return code.", "red")
    cprint("Input file:", in_file, "red")
    cprint("Output file:", out_file, "red")
    sys.exit(1)

if not os.path.isfile(out_file):
    cprint("Cropping with `ncks` failed: No output file created.", "red")
    cprint("Input file:", in_file, "red")
    cprint("Output file:", out_file, "red")
    sys.exit(1)
