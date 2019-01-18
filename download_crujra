#!/bin/python

# This script will download all CRU JRA-55 files (version 1.1.5) into the
# CRU-JRA directory specified in "options.yaml".

import os
from shutil import which
from subprocess import run
from sys import exit

import yaml
from termcolor import cprint

folder = yaml.load(open("options.yaml"))["directories"]["crujra_orig"]

if not os.path.isdir(folder):
    cprint("Creating directory '%s'." % folder, 'yellow')
    os.makedirs(folder)

if which('wget') is None:
    cprint("Command `wget` is not available.", "red")
    exit(1)

url_prefix = "https://vesg.ipsl.upmc.fr/thredds/fileServer/work/p529viov/crujra/"

for year in range(1958, 2018):
    filename = "crujra.V1.1.5d.pre.%d.365d.noc.nc.gz" % year
    cprint("Downloading '%s'..." % filename, 'yellow')
    run(["wget",
         "--directory-prefix=%s" % folder,
         "%s%s" % (url_prefix, filename)])

cprint('Finished downloading.', 'green')
exit(0)
