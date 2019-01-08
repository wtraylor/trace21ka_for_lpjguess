from termcolor import cprint
import os
import subprocess


def crop_file(in_file, out_file, ext):
    """Crop a NetCDF file to give rectangle.

    Args:
        in_file: Input file path.
        out_file: Output file path. It will be overwritten without warning.
        ext: The rectangular region (extent) to crop to, given as a list of
        [lon1, lon2, lat1, lat2].

    Raises:
        RuntimeError
    """
    cprint("Cropping file '%s'..." % in_file, "green")
    if not os.path.isfile(in_file):
        raise FileNotFoundError("Input file doesn’t exist: '%s'" % in_file)
    status = subprocess.run(["ncks",
                             "--overwrite",
                             "--dimension", "lon,%.2f,%.2f" % (ext[0], ext[1]),
                             "--dimension", "lat,%.2f,%.2f" % (ext[0],
                                                               ext[1]),
                             in_file,
                             out_file]).returncode
    if status != 0:
        raise RuntimeError("Cropping with `ncks` failed: Bad return code.")
    if not os.path.isfile(out_file):
        raise RuntimeError("Cropping with `ncks` failed: No output file "
                           "created.")
