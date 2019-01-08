from termcolor import cprint
import os
import subprocess


def crop_file(in_file, out_file, ext):
    """Crop a NetCDF file to give rectangle using NCO.

    Args:
        in_file: Input file path.
        out_file: Output file path. It will be overwritten without warning.
        ext: The rectangular region (extent) to crop to, given as a list of
        [lon1, lon2, lat1, lat2].

    Returns:
        Name of output file (same as `out_file`).

    Raises:
        FileNotFoundError: `in_file` doesn’t exist.
        RuntimeError: NCKS failed or no output file was created.
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
    return [crop_file(f, os.path.join(out_dir, os.path.basename(f)), ext)
            for f in filelist]
