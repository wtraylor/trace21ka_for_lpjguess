import os
import re
import shutil
import subprocess


def get_cru_filenames():
    """Create list of original CRU files between 1900 and 1990."""
    years = [(y+1, y+10) for y in range(1920, 1971, 10)]
    vars = ['pre', 'wet', 'tmp']
    # Combine every time segment (decade) with every variable.
    years_vars = tuple((y1, y2, v) for (y1, y2) in years for v in vars)
    return ["cru_ts4.01.%d.%d.%s.dat.nc" % (y1, y2, v) for (y1, y2, v) in
            years_vars]


def get_crujra_filenames():
    """Create a list of all original CRU-JRA filenames from 1958 to 1990."""
    return [f'crujra.V1.1.5d.pre.{year}.365d.noc.nc' for year in
            range(1958, 1991)]


def get_modern_trace_filename(var: str):
    """Compose the name for the most recent TraCE-21ka NetCDF file."""
    return f'trace.36.400BP-1990CE.cam2.h0.{var}.2160101-2204012.nc'


def get_time_range_of_trace_file(filename):
    """Get the time range in years BP covered by given TraCE-21ka file.

    Args:
        filename: The base filename (without path!) of the TraCE file. The file
            name must not have been altered!

    Returns:
        A list with two integers defining beginning and end of time range in
        years BP.

    Raises:
        ValueError: If `filename` does not match the original TraCE-21ka naming
            pattern as expected.
    """
    try:
        # For the youngest TraCE file, the time range goes to 1990 CE, which
        # translates to -40 BP.
        if 'CE' in filename:
            return [400, -40]
        match_obj = re.match(r'trace\.\d\d\.(\d+)-(\d+)BP.*', filename)
        start = int(match_obj.group(1))
        end = int(match_obj.group(2))
        return [start, end]
    except Exception:
        raise ValueError("Given file name does not match TraCE-21ka naming "
                         f"pattern: '{filename}'")


def get_all_trace_filenames(variables: list):
    """Create a list of ALL original TraCE-21ka NetCDF filenames.

    Args:
        variables: List with the CAM variable names.

    Returns:
        A list of strings with the TraCE filenames.
    """
    result = list()
    for v in variables:
        result += ['trace.01.22000-20001BP.cam2.h0.%s.0000101-0200012.nc' % v,
                   'trace.02.20000-19001BP.cam2.h0.%s.0200101-0300012.nc' % v,
                   'trace.03.19000-18501BP.cam2.h0.%s.0300101-0350012.nc' % v,
                   'trace.04.18500-18401BP.cam2.h0.%s.0350101-0360012.nc' % v,
                   'trace.05.18400-17501BP.cam2.h0.%s.0360101-0450012.nc' % v,
                   'trace.06.17500-17001BP.cam2.h0.%s.0450101-0500012.nc' % v,
                   'trace.07.17000-16001BP.cam2.h0.%s.0500101-0600012.nc' % v,
                   'trace.08.16000-15001BP.cam2.h0.%s.0600101-0700012.nc' % v,
                   'trace.09.15000-14901BP.cam2.h0.%s.0700101-0710012.nc' % v,
                   'trace.10.14900-14351BP.cam2.h0.%s.0710101-0765012.nc' % v,
                   'trace.11.14350-13871BP.cam2.h0.%s.0765101-0813012.nc' % v,
                   'trace.12.13870-13101BP.cam2.h0.%s.0813101-0890012.nc' % v,
                   'trace.13.13100-12901BP.cam2.h0.%s.0890101-0910012.nc' % v,
                   'trace.14.12900-12501BP.cam2.h0.%s.0910101-0950012.nc' % v,
                   'trace.15.12500-12001BP.cam2.h0.%s.0950101-1000012.nc' % v,
                   'trace.16.12000-11701BP.cam2.h0.%s.1000101-1030012.nc' % v,
                   'trace.17.11700-11301BP.cam2.h0.%s.1030101-1070012.nc' % v,
                   'trace.18.11300-10801BP.cam2.h0.%s.1070101-1120012.nc' % v,
                   'trace.19.10800-10201BP.cam2.h0.%s.1120101-1180012.nc' % v,
                   'trace.20.10200-09701BP.cam2.h0.%s.1180101-1230012.nc' % v,
                   'trace.21.09700-09201BP.cam2.h0.%s.1230101-1280012.nc' % v,
                   'trace.22.09200-08701BP.cam2.h0.%s.1280101-1330012.nc' % v,
                   'trace.23.08700-08501BP.cam2.h0.%s.1330101-1350012.nc' % v,
                   'trace.24.08500-08001BP.cam2.h0.%s.1350101-1400012.nc' % v,
                   'trace.25.08000-07601BP.cam2.h0.%s.1400101-1440012.nc' % v,
                   'trace.26.07600-07201BP.cam2.h0.%s.1440101-1480012.nc' % v,
                   'trace.27.07200-06701BP.cam2.h0.%s.1480101-1530012.nc' % v,
                   'trace.28.06700-06201BP.cam2.h0.%s.1530101-1580012.nc' % v,
                   'trace.29.06200-05701BP.cam2.h0.%s.1580101-1630012.nc' % v,
                   'trace.30.05700-05001BP.cam2.h0.%s.1630101-1700012.nc' % v,
                   'trace.31.05000-04001BP.cam2.h0.%s.1700101-1800012.nc' % v,
                   'trace.32.04000-03201BP.cam2.h0.%s.1800101-1880012.nc' % v,
                   'trace.33.03200-02401BP.cam2.h0.%s.1880101-1960012.nc' % v,
                   'trace.34.02400-01401BP.cam2.h0.%s.1960101-2060012.nc' % v,
                   'trace.35.01400-00401BP.cam2.h0.%s.2060101-2160012.nc' % v,
                   'trace.36.400BP-1990CE.cam2.h0.%s.2160101-2204012.nc' % v]
    return result


def ranges_overlap(range1, range2):
    """Whether two 2-element lists have an overlap.

    Args:
        range1, range2: Each a 2-element list with numbers.

    Returns:
        True if there is overlap, False otherwise.

    Raises:
        TypeError: An argument is not a list.
        ValueError: One of the list doesn’t have exactly 2 elements.
    """
    if not isinstance(range1, list) or not isinstance(range2, list):
        raise TypeError('Both arguments must be a list.')
    if len(range1) != 2 or len(range2) != 2:
        raise ValueError('Both lists must have two elements each.')
    if max(range1) < min(range2):
        return False
    if max(range2) < min(range1):
        return False
    return True


def get_trace_filenames(variables, time_range):
    """Get the list of original TraCE-21ka filenames that cover the time range.

    Args:
        variables: A list of TraCE variables (can also be a single string).
        time_range: A list with two integers, the start and end of the time
            frame in years BP. Values must lie between 22000 BP and -40 BP
            (i.e. 1990 CE).

    Returns:
        List of file names.

    Raises:
        ValueError: If `time_range` is not valid.
    """
    if not isinstance(variables, list):
        variables = [variables]
    if min(time_range) < -40 or max(time_range) > 22000:
        raise ValueError('The given time range is invalid. The numbers must '
                         'lie between 22000 BP and -40 BP (=1990 CE). I got '
                         f'this: {time_range}')
    all_files = get_all_trace_filenames(variables)
    result = list()
    for f in all_files:
        if ranges_overlap(time_range, get_time_range_of_trace_file(f)):
            result += [f]
    return result


def derive_new_trace_name(trace_file):
    """Compose a new basename for a TraCE file with already absolute calendar.

    Args:
        trace_file: An existing TraCE NetCDF file.

    Returns:
        String with the new base filename.

    Raises:
        FileNotFoundError: If `trace_file` does not exist.
        RuntimeError: `cdo` command is not in the PATH.
    """
    if not os.path.isfile(trace_file):
        raise FileNotFoundError(f"Could not find TraCE file '{trace_file}'.")
    if not shutil.which('cdo'):
        raise RuntimeError('`cdo` command is not in the PATH.')
    # Get beginning and end:
    stdout = subprocess.run(
        ['cdo', 'showdate', '-select,timestep=1,-1', trace_file],
        check=True, capture_output=True, encoding='utf-8'
    ).stdout
    first_year, last_year = re.findall(r' (\d+)-\d\d-\d\d', stdout)
    del stdout
    first_year = int(first_year)
    last_year = int(last_year)
    # Get variable name:
    stdout = subprocess.run(['cdo', 'showname', trace_file],
                            capture_output=True, encoding='utf-8').stdout
    var = stdout.split()[0]  # Take the first variable.
    name = f'trace_{var}_{first_year}-{last_year}.nc'
    return name
