from os.path import isfile
from subprocess import run


def aggregate_monthly_means(in_file, out_file):
    """Calculate the mean over all years for each month using CDO.

    The resulting file has then exactly 12 values per grid cell: one
    average per month.

    Args:
        in_file: Input NetCDF file path.
        out_file: Path to output file (will be overwritten).

    Returns:
        The output file (equals `out_file`).

    Raises:
        FileNotFoundError: The file `in_file` wasn’t found.
        RuntimeError: The `cdo` command returned an error or the output
            file wasn’t created.
    """
    if not isfile(in_file):
        raise FileNotFoundError("Input file doesn’t exist: '%s'" % in_file)
    status = run(["cdo", "ymonmean", in_file, out_file])
    if status != 0:
        raise RuntimeError("Cropping with `ncks` failed: Bad return code.")
    if not isfile(out_file):
        raise RuntimeError("Cropping with `ncks` failed: No output file "
                           "created.")
    return out_file
