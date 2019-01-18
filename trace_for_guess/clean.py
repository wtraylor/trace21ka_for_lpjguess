#!/usr/bin/env python

# Remove all files in the `heap` and the `output` directory.

import glob
import os

import yaml
from termcolor import cprint


def confirm(prompt, filelist):
    """Prompt the user for confirmation."""
    while True:
        cprint(prompt, 'green')
        cprint('(y)es, (n)o, or (l)ist files.', 'green')
        answer = input('')
        if answer in 'yY':
            return True
        elif answer in 'nN':
            return False
        elif answer in 'lL':
            print(filelist)
        else:
            cprint('Please enter y, n, or l.', 'green')


dirs = yaml.load(open('options.yaml'))['directories']

heap_files = glob.glob(os.path.join(dirs['heap'], '**'))
if heap_files:
    if confirm('Do you want to delete all intermediary files in the heap?',
               heap_files):
        for f in heap_files:
            cprint(f"Deleting '{f}''", 'yellow')
            os.remove(f)
else:
    cprint('No files to delete in the heap directory.', 'green')

out_files = glob.glob(os.path.join(dirs['output'], '**'))
if out_files:
    if confirm("Do you want to delete all output files?", out_files):
        for f in out_files:
            cprint(f"Deleting '{f}''", 'yellow')
            os.remove(f)
else:
    cprint('No output files to delete.', 'green')

cprint('Done', 'green')
