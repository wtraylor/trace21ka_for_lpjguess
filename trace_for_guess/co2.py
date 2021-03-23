# SPDX-FileCopyrightText: 2021 Wolfgang Traylor <wolfgang.traylor@senckenberg.de>
#
# SPDX-License-Identifier: MIT

import os

import subprocess
from termcolor import cprint

from trace_for_guess.filenames import get_co2_filename
from trace_for_guess.netcdf_metadata import get_metadata_from_trace_file
from trace_for_guess.skip import skip


def get_co2_values(trace_file):
    """Get average CO₂ values per year from TraCE-21ka file.

    We use `cdo` to read the values because xarray cannot parse the dates
    correctly for youngest TraCE data (year numbers are too high).

    Returns:
        A dictionary with year as key and CO₂ concentration as value.
    """
    if not os.path.isfile(trace_file):
        raise FileNotFoundError(f"Input file not found: '{trace_file}'")
    stdout = subprocess.run(['cdo', 'output', '-yearmean',
                             '-selvar,co2vmr', trace_file], check=True,
                            encoding='utf-8', capture_output=True).stdout
    co2_vals = [float(v) for v in stdout.split()]
    del stdout
    stdout = subprocess.run(['cdo', 'showyear', trace_file], check=True,
                            encoding='utf-8', capture_output=True).stdout
    years = [int(s) for s in stdout.split()]
    assert len(years) == len(co2_vals),\
        f'len(years)=={len(years)}, len(co2_vals)=={len(co2_vals)}'
    return dict(zip(years, co2_vals))


def create_co2_files(trace_files, out_dir):
    """Create CO₂ files for LPJ-GUESS from TraCE-21ka files.

    For each single input file, there will be a CO₂ file created.

    Args:
        trace_files: A list with contiguous TraCE-21ka files.
        out_dir: Output directory.

    Raises:
        FileNotFoundError: A file in `trace_files` does not exist.
    """
    co2_files = dict()  # key = TraCE file path; value = CO₂ file path
    for f in trace_files:
        if not os.path.isfile(f):
            raise FileNotFoundError(f"Input file not found: '{f}'")
        metadata = get_metadata_from_trace_file(f)
        basename = get_co2_filename(metadata['first_year'],
                                    metadata['last_year'])
        co2_files[f] = os.path.join(out_dir, basename)
    if skip(trace_files, list(co2_files.values())):
        return
    try:
        for f in trace_files:
            co2_vals = get_co2_values(f)
            with open(co2_files[f], 'w') as out:
                for year in co2_vals:
                    # The CO₂ values in the TraCE file are by a factor of 10^6
                    # smalller # than what LPJ-GUESS expects, that’s why we
                    # need to multiply here. The result is good to be taken
                    # with integer precision.
                    val = int(co2_vals[year] * 1e6)
                    line = f'{year}\t{val}\n'
                    out.write(line)
    except Exception:
        for f in list(co2_files.values()):
            if os.path.isfile(f):
                cprint(f"Removing file '{f}'.", 'red')
                os.remove(f)
        raise
    for f in co2_files.values():
        assert os.path.isfile(f)
    cprint('Successfully created CO₂ files:', 'green')
    for f in co2_files.values():
        cprint('\t' + f, 'green')
