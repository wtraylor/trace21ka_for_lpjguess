#!/bin/python

from termcolor import cprint
import os
import subprocess
import sys
import yaml

# Name of this script file.
scriptfile = os.path.basename(__file__) + ": "

regrid_alg = yaml.load(open("options.yaml"))["regrid_algorithm"]

if len(sys.argv) != 3:
    cprint(scriptfile + "Please provide exacty two command line arguments.", "red")
    cprint(scriptfile + "<input file> <output file>", "red")
    sys.exit(1)
in_file = sys.argv[1]
out_file = sys.argv[2]

if not os.path.isfile(in_file):
    cprint(scriptfile + "First argument is not a file: '%s'" % in_file, "red")
    sys.exit(1)

# Template grid.
grid_templ = "heap/grid_template.nc"

if not os.path.isfile(grid_templ):
    cprint(scriptfile + "Grid template file does not exist: '%s'" % grid_templ,
           "red")
    sys.exit(1)

cprint(scriptfile + "'%s' => '%s'" % (in_file, out_file), "green")

status = subprocess.run(["ncremap",
                         "--algorithm=%s" % regrid_alg,
                         "--template_file=%s" % grid_templ,
                         "--input_file=%s" % in_file,
                         "--output_file=%s" % out_file])

if not os.path.isfile(out_file):
    cprint(scriptfile + "Regridding with `ncremap` failed: No output file "
           "created.", "red")
    cprint("Input file:", in_file, "red")
    cprint("Output file:", out_file, "red")
    sys.exit(1)
