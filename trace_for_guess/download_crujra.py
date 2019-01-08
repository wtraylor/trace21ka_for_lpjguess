#!/bin/python

# This script will download all CRU JRA-55 files (version 1.1.5) into current
# working directory.

import subprocess

url_prefix = "https://vesg.ipsl.upmc.fr/thredds/fileServer/work/p529viov/crujra/"

for year in range(1958, 2018):
    filename = "crujra.V1.1.5d.pre.%d.365d.noc.nc.gz" % year
    print("Downloading '%s'..." % filename)
    subprocess.run(["wget", "%s%s" % (url_prefix, filename)])
