import json
import os
import shutil
import subprocess
from glob import glob

from termcolor import cprint

from trace_for_guess.skip import skip


def adjust_longitude(netcdf_file, lon):
    """Convert longitude to correct range, matching the NetCDF file.

    If the file’s longitude is in [0,360) °E, and `lon` is negative (in
    [-180,0)), the result is a positive value in [0,360). The same goes the
    other way round.

    It is assumed that the longitude variable in the NetCDF file is named
    'lon'.

    Args:
        netcdf_file: Path to NetCDF file.
        lon: Longitude value.

    Returns:
        Longitude value in correct range.

    Raises:
        ValueError: If `lon` is either <-180 or >=360.
        FileNotFoundError: `netcdf_file` doesn’t exist.
    """
    if not os.path.isfile(netcdf_file):
        raise FileNotFoundError("Input file doesn’t exist: '%s'" % netcdf_file)
    if lon < -180 or lon >= 360:
        raise ValueError("Longitude value is out of any supported range: %.2f"
                         % lon)
    # Get longitude range of the file.
    stdout = subprocess.run(['ncks',
                             '--json',
                             '--variable', 'lon',
                             '--dimension', 'lon,0',  # first entry
                             '--dimension', 'lon,-1',  # last entry
                             netcdf_file],
                            check=True,
                            encoding='utf-8',
                            capture_output=True).stdout
    j = json.loads(stdout)
    file_range = j['variables']['lon']['data']  # a 2-elements list
    # Convert longitude to [-180,+180) °E format.
    if min(file_range) < 0 and lon > 180:
        return lon - 360
    # Convert longitude to [0,360) °E format.
    elif max(file_range) > 180 and lon < -180:
        return lon + 360
    else:
        return lon


def crop_file(in_file, out_file, ext):
    """Crop a NetCDF file to give rectangle using NCO.

    The file is automatically converted to [0,360] °E longitude format.

    Args:
        in_file: Input file path.
        out_file: Output file path. It will not be overwritten.
        ext: The rectangular region (extent) to crop to, given as a list of
            [lon1, lon2, lat1, lat2]. Longitude in [0,360) °E and latitude in
            [-90,+90] °N.

    Returns:
        Name of output file (same as `out_file`).

    Raises:
        FileNotFoundError: `in_file` doesn’t exist.
        RuntimeError: Executable `ncks` is not in the PATH.
        RuntimeError: NCKS failed or no output file was created.
    """
    if not os.path.isfile(in_file):
        raise FileNotFoundError("Input file doesn’t exist: '%s'" % in_file)
    if skip(in_file, out_file):
        return out_file
    out_dir = os.path.dirname(out_file)
    if not os.path.isdir(out_dir):
        cprint(f"Directory '{out_dir}' does not exist yet. I will create it.",
               'yellow')
        os.makedirs(out_dir)
    cprint("Cropping file '%s'..." % in_file, 'yellow')
    if shutil.which("ncks") is None:
        raise RuntimeError("Executable `ncks` not found.")
    try:
        # ADJUST LONGITUDE
        ext_adj = list()
        ext_adj[:] = ext
        ext_adj[0] = adjust_longitude(in_file, ext[0])
        ext_adj[1] = adjust_longitude(in_file, ext[1])
        # CROP
        subprocess.run(["ncks",
                        "--overwrite",
                        "--dimension", "lon,%.2f,%.2f" % (ext_adj[0],
                                                          ext_adj[1]),
                        "--dimension", "lat,%.2f,%.2f" % (ext_adj[2],
                                                          ext_adj[3]),
                        in_file,
                        out_file], check=True)
        # ROTATE LONGITUDE
        # See here for the documentation about rotating longitude:
        # http://nco.sourceforge.net/nco.html#msa_usr_rdr
        # Note that we rotate after cropping for performance reasons. This way,
        # only the cropped grid cells need to be rotated.
        if min(ext_adj[0:2]) < 0 and max(ext_adj[0:2]) > 0:
            # If the longitude range goes around the 180° line, the Eastern and
            # the Western half of the longitude ranges are re-ordered: The
            # Eastern half comes first, then the Western half. This is then the
            # correct order for the 0–360 ° format.
            subprocess.run(['ncks',
                            '--dimension', 'lon,0.,180.',
                            '--dimension', 'lon,-180.,-0.1',
                            '--msa_user_order',
                            out_file,
                            out_file], check=True)
        subprocess.run(['ncap2',
                        '--overwrite',
                        '--script', 'where(lon < 0) lon=lon+360',
                        out_file, out_file], check=True)
    except Exception:
        print(f'DEBUG: ext = {ext}')
        print(f'DEBUG: ext_adj = {ext_adj}')
        if os.path.isfile(out_file):
            cprint(f"Removing file '{out_file}'.", 'red')
            os.remove(out_file)
        # Remove temporary file created by ncks.
        for g in glob(f'{out_file}.pid*.ncks.tmp'):
            cprint(f"Removing file '{g}'.", 'red')
            os.remove(g)
        raise
    if not os.path.isfile(out_file):
        raise RuntimeError("Cropping with `ncks` failed: No output file "
                           "created.")
    cprint(f"Successfully created '{out_file}'.", 'green')
    return out_file


def crop_file_list(filelist, out_dir, ext):
    """Crop all files in the list and store the output files in a directory.

    Args:
        filelist: List of input NetCDF file paths.
        out_dir: Path to output directory.
        ext: The rectangular region (extent) to crop to, given as a list of
        [lon1, lon2, lat1, lat2].

    Returns:
        List of paths to cropped files.
    """
    if not os.path.isdir(out_dir):
        cprint(f"Directory '{out_dir}' does not exist yet. I will create it.",
               'yellow')
        os.makedirs(out_dir)
        assert os.path.isdir(out_dir), 'Dir was not created.'
    result_list = list()
    for f in filelist:
        try:
            out_file = os.path.join(out_dir, os.path.basename(f))
            result_list += [crop_file(f, out_file, ext)]
            assert os.path.isfile(result_list[-1]), 'Cropped file not created.'
        except Exception:
            if os.path.isfile(out_file):
                cprint(f"Removing file '{out_file}'.", 'red')
                os.remove(out_file)
            # Remove temporary file created by ncks.
            for g in glob(f'{out_file}.pid*.ncks.tmp'):
                cprint(f"Removing file '{g}'.", 'red')
                os.remove(g)
            raise
    assert len(filelist) == len(result_list), \
        'Lengths of input and return list don’t match up: '\
        f'len(filelist)={len(filelist)} does not equal '\
        f'len(result_list)={len(result_list)}'
    return result_list


def expand_extent(extent, margin):
    """Make the rectangular region bigger by a given amount to all directions.

    Args:
        extent: The rectangular given as a list of [lon1, lon2, lat1, lat2].
            Longitude in [0,360) °E and latitude in [-90,+90] °N.
        margin: The amount to extend into all four directions. (one number)

    Returns:
        Expanded extent as a list of [lon1, lon2, lat1, lat2].

    Most simple case:
    >>> expand_extent([20, 200, -10, 10], 10)
    [10, 210, -20, 20]

    Don’t go beyond 90° North or South:
    >>> expand_extent([20, 200, -85, 85], 10)
    [10, 210, -90, 90]

    Cover the whole globe:
    >>> expand_extent([0, 360, -90, 90], 10)
    [0, 360, -90, 90]

    Circle around 0° longitude:
    >>> expand_extent([0, 30, -10, 10], 10)
    [350, 40, -20, 20]
    >>> expand_extent([20, 355, -10, 10], 10)
    [10, 5, -20, 20]

    Special Case 1: lon1 and lon2 are so close that by expanding them, they
    close around the whole globe.
    >>> expand_extent([20, 15, -10, 10], 10)
    [0, 360, -20, 20]

    Special Case 2.1: lon1 and lon2 both expand around the 0°/360° boundary so
    that they close around the whole globe.
    >>> expand_extent([5, 359, -10, 10], 10)
    [0, 360, -20, 20]

    Special Case 2.2: Only lon2 expands beyond 360°, but then it overlaps with
    the expanded lon1, and they close around the whole globe.
    >>> expand_extent([11, 359, -10, 10], 10)
    [0, 360, -20, 20]

    Special Case 3: Only lon1 expands beyond 0°, but then it overlaps with the
    expanded lon2, and they close again around the whole globe.
    >>> expand_extent([1, 349, -10, 10], 10)
    [0, 360, -20, 20]
    """
    result = list()
    result[:] = extent
    lon1, lon2 = extent[0:2]
    lat1, lat2 = extent[2:4]
    # LONGITUDE
    if lon1 > lon2 and (lon1 - margin) < (lon2 + margin):
        # Special Case 1
        result[0] = 0
        result[1] = 360
    elif (lon1 < lon2 and lon2 + margin >= 360 and
          lon1 - margin < (lon2 + margin) % 360):
        # Special Case 2
        result[0] = 0
        result[1] = 360
    elif (lon1 < lon2 and lon1 - margin <= 0 and
          lon2 + margin > (lon1 - margin) % 360):
        # Special Case 3
        result[0] = 0
        result[1] = 360
    else:
        # The normal case.
        result[0] = (lon1 - margin) % 360
        result[1] = (lon2 + margin) % 360
    # LATITUDE
    result[2] = max(-90, lat1 - margin)
    result[3] = min(+90, lat2 + margin)
    return result


def check_region(extent):
    """Check if region [lon1, lon2, lat1, lat2] is good.

    Args:
        extent: The rectangular given as a list of [lon1, lon2, lat1, lat2].
            Longitude in [0,360) °E and latitude in [-90,+90] °N.

    Raises:
        ValueError: If `extent` is not a list with 4 numbers.
        RuntimeError: If the numbers `extent` are not valid.
    """
    if not isinstance(extent, list):
        raise ValueError('Argument "extent" is not a list.')
    if not len(extent) == 4:
        raise ValueError(f'The list "extent" has not 4 elements: {extent}')
    if not all([isinstance(i, (int, float)) for i in extent]):
        raise ValueError('The list "extent" contains non-numerical elements: '
                         f'{extent}')
    lon1, lon2, lat1, lat2 = extent
    if lon1 < 0 or lon1 > 360:
        raise RuntimeError(f'Longitude 1 is out of range: {lon1}')
    if lon2 < 0 or lon2 > 360:
        raise RuntimeError(f'Longitude 2 is out of range: {lon2}')
    if lon1 == lon2:
        raise RuntimeError(f'Longitude values are equal: {lon1} == {lon2}')
    if lat1 > 90 or lat1 < -90:
        raise RuntimeError(f'Latitude 1 is out of range: {lat1}')
    if lat2 > 90 or lat2 < -90:
        raise RuntimeError(f'Latitude 2 is out of range: {lat2}')
    if lat1 >= lat2:
        raise RuntimeError(f'Latitude 1 is greater or equal than latitude 2: '
                           f'{lat1} >= {lat2}')
