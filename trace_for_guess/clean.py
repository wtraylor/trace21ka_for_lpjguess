#!/usr/bin/env python

# SPDX-FileCopyrightText: 2021 Wolfgang Traylor <wolfgang.traylor@senckenberg.de>
#
# SPDX-License-Identifier: MIT

# Remove all files in the `heap` and the `output` directory.

import glob
import os
import sys

import yaml
from termcolor import cprint


def confirm(prompt, filelist):
    """Prompt the user for confirmation."""
    while True:
        cprint(prompt, 'green')
        print('(y)es, (n)o, (l)ist files, or (q)uit.')
        answer = input('')
        if answer in 'yY':
            return True
        elif answer in 'nN':
            return False
        elif answer in 'lL':
            for f in filelist:
                print(f)
        elif answer in 'qQ':
            cprint('User canceled cleaning.', 'red')
            sys.exit(0)
        else:
            cprint('Please enter y, n, l, or q.', 'red')


dirs = yaml.load(open('options.yaml'))['directories']
heap = dirs['heap']
heap_input = os.path.join(heap, '0_input')
out_dir = dirs['output']

extracted_files = glob.glob(os.path.join(heap_input, '**'))
if extracted_files:
    if confirm('Do you want to delete all extracted input files in the heap? '
               '(Usually not necessary.)', extracted_files):
        for f in extracted_files:
            cprint(f"Deleting '{f}''", 'yellow')
            os.remove(f)
else:
    cprint('No extracted input files to delete in the heap directory.',
           'green')

# Use absolute paths for extracted files in order to compare them with other
# heap files.
dont_delete = list()
for f in extracted_files:
    dont_delete += [os.path.abspath(f)]

heap_files = list()
for root, dirs, files in os.walk(heap):
    for f in files:
        f = os.path.join(root, f)
        if not os.path.abspath(f) in dont_delete:
            heap_files += [f]
if heap_files:
    if confirm('Do you want to delete all intermediary files in the heap?',
               heap_files):
        for f in heap_files:
            cprint(f"Deleting '{f}'", 'yellow')
            os.remove(f)
        for root, dirs, files in os.walk(heap, topdown=False):
            for d in dirs:
                d = os.path.join(root, d)
                if not os.listdir(d):
                    cprint(f"Deleting empty directory '{d}'", 'yellow')
                    os.rmdir(d)
else:
    cprint('No processed files to delete in the heap directory.', 'green')

out_files = glob.glob(os.path.join(out_dir, '**'))
if out_files:
    if confirm("Do you want to delete all output files?", out_files):
        for f in out_files:
            cprint(f"Deleting '{f}''", 'yellow')
            os.remove(f)
else:
    cprint('No output files to delete.', 'green')

cprint('Done', 'green')
sys.exit(0)
