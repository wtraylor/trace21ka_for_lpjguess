import os

import xarray as xr
from termcolor import cprint

from trace_for_guess.skip import skip


def year_from_date(date):
    """Extract the year from the "%Y%m%d.%f"-formatted floating point date."""
    s = str(date)
    # Drop the last 6 digits ('MMDD.0').
    s = s[:-6]
    return int(s)


def create_co2_file(trace_files, co2_file):
    """Create a CO₂ file for LPJ-GUESS from TraCE-21ka files.

    TODO: The `year` column must be continuously incrementing calendar years.

    Args:
        trace_files: A list with contiguous TraCE-21ka files.
        co2_file: Output file.

    Raises:
        FileNotFoundError: A file in `trace_files` does not exist.
    """
    for f in trace_files:
        if not os.path.isfile(f):
            raise FileNotFoundError(f"Input file not found: '{f}'")
    if skip(trace_files, co2_file):
        return
    try:
        with open(co2_file, 'w') as out_file:
            for f in trace_files:
                with xr.open_dataset(f, decode_times=False) as ds:
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
                            out_file.write(f'{prev_year}\t{mean}\n')
                            values_in_year = sum_values = 0
                        prev_year = year
                    # Write the last year.
                    if values_in_year:
                        mean = sum_values / values_in_year
                        out_file.write(f'{prev_year}\t{mean}\n')
    except Exception:
        if os.path.isfile(co2_file):
            cprint(f"Removing file '{co2_file}'.", 'red')
            os.remove(co2_file)
        raise
    assert(os.path.isfile(co2_file))
    cprint(f"Successfully created file: '{co2_file}'", 'green')
