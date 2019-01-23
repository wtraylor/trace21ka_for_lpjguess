import os
from glob import glob
from shutil import which
from subprocess import run

from termcolor import cprint


def crop_file(in_file, out_file, ext):
    """Crop a NetCDF file to give rectangle using NCO.

    Args:
        in_file: Input file path.
        out_file: Output file path. It will not be overwritten.
        ext: The rectangular region (extent) to crop to, given as a list of
        [lon1, lon2, lat1, lat2].

    Returns:
        Name of output file (same as `out_file`).

    Raises:
        FileNotFoundError: `in_file` doesn’t exist.
        RuntimeError: Executable `ncks` is not in the PATH.
        RuntimeError: NCKS failed or no output file was created.
    """
    cprint("Cropping file '%s'..." % in_file, 'yellow')
    if not os.path.isfile(in_file):
        raise FileNotFoundError("Input file doesn’t exist: '%s'" % in_file)
    if os.path.isfile(out_file):
        cprint(f"Output file '{out_file}' already exists. Skipping.", 'cyan')
        return out_file
    if which("ncks") is None:
        raise RuntimeError("Executable `ncks` not found.")
    status = run(["ncks",
                  "--overwrite",
                  "--dimension", "lon,%.2f,%.2f" % (ext[0], ext[1]),
                  "--dimension", "lat,%.2f,%.2f" % (ext[2], ext[3]),
                  in_file,
                  out_file]).returncode
    if status != 0:
        raise RuntimeError("Cropping with `ncks` failed: Bad return code.")
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
        assert(os.path.isdir(out_dir))
    result_list = list()
    for f in filelist:
        try:
            out_file = os.path.join(out_dir, os.path.basename(f))
            result_list += crop_file(f, out_file, ext)
            assert(os.path.isfile(out_file))
        except:
            if os.path.isfile(out_file):
                cprint(f"Removing file '{out_file}'.", 'red')
                os.remove(out_file)
            # Remove temporary file created by ncks.
            for g in glob(f'{out_file}.pid*.ncks.tmp'):
                cprint(f"Removing file '{g}'.", 'red')
                os.remove(g)
            raise
