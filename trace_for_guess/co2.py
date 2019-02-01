import re
import os

import subprocess
import shutil
from termcolor import cprint

from trace_for_guess.filenames import get_co2_filename
from trace_for_guess.netcdf_metadata import (get_metadata_from_trace_file,
                                             get_metadata_from_trace_files)
from trace_for_guess.skip import skip


def year_from_date(date):
    """Extract the year from the "%Y%m%d.%f"-formatted floating point date."""
    s = str(date)
    # Drop the last 6 digits ('MMDD.0').
    s = s[:-6]
    return int(s)


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


def create_co2_files(trace_files, out_dir, concat):
    """Create CO₂ files for LPJ-GUESS from TraCE-21ka files.

    For each single input file, there will be a CO₂ file created. In addition,
    a concatenated CO₂ can be created covering all TraCE files in the list.

    TODO: The `year` column must be continuously incrementing calendar years.

    Args:
        trace_files: A list with contiguous TraCE-21ka files.
        out_dir: Output directory.
        concat: Whether to create an additional CO₂ file covering all TraCE
            files.

    Raises:
        FileNotFoundError: A file in `trace_files` does not exist.
    """
    co2_files = dict()  # key = TraCE file path; value = CO₂ file path
    for f in trace_files:
        if not os.path.isfile(f):
            raise FileNotFoundError(f"Input file not found: '{f}'")
        metadata = get_metadata_from_trace_file(f)
        co2_files[f] = (
            os.path.join(out_dir, get_co2_filename(metadata['first_year'],
                                                   metadata['last_year']))
        )
        del metadata
    metadata = get_metadata_from_trace_files(trace_files)
    co2_concat = os.path.join(out_dir, get_co2_filename(metadata['first_year'],
                                                        metadata['last_year']))
    if skip(trace_files, list(co2_files.values()) + [co2_concat]):
        return
    try:
        with open(co2_concat, 'w') as out_concat:
            for f in trace_files:
                co2_vals = get_co2_values(f)
                with open(co2_files[f], 'w') as out_single:
                    for year in co2_vals:
                        val = co2_vals[year]
                        line = f'{year}\t{val}\n'
                        out_concat.write(line)
                        out_single.write(line)
    except Exception:
        for f in list(co2_files.values()) + [co2_concat]:
            if os.path.isfile(f):
                cprint(f"Removing file '{f}'.", 'red')
                os.remove(f)
        raise
    assert os.path.isfile(co2_concat)
    for f in co2_files.values():
        assert os.path.isfile(f)
    if not concat:
        os.remove(co2_concat)
    cprint('Successfully created files:', 'green')
    cprint('\t' + co2_concat, 'green')
    for f in co2_files.values():
        cprint('\t' + f, 'green')
