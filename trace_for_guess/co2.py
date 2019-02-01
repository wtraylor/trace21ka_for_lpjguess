import os

import xarray as xr
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
                with xr.open_dataset(f, decode_times=False) as ds, \
                        open(co2_files[f], 'w') as out_single:
                    co2 = ds['co2vmr']
                    prev_year = values_in_year = sum_values = 0
                    for i in range(len(co2.values)):
                        year = year_from_date(co2['time'].values[i])
                        value = co2.values[i]
                        if year == prev_year or values_in_year == 0:
                            # Before the year is completed, only record data
                            # for calculating the mean.
                            values_in_year += 1
                            sum_values += value
                        else:
                            # We have completed one year and write the
                            # arithmetic mean to output.
                            mean = sum_values / values_in_year
                            line = f'{prev_year}\t{mean}\n'
                            out_concat.write(f'{prev_year}\t{mean}\n')
                            out_single.write(line)
                            values_in_year = sum_values = 0
                        prev_year = year
                    # Write the last year.
                    if values_in_year:
                        mean = sum_values / values_in_year
                        line = f'{prev_year}\t{mean}\n'
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
