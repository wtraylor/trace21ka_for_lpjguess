from termcolor import cprint
import os
import subprocess


def cat_files(filelist, out_file):
    """Concatenate a list of NetCDF files using NCO (i.e. ncrcat).

    Args:
        filelist: List of input file paths.
        out_file: Path to concatenated output file (will be overwritten).

    Raises:
        FileNotFoundError: A file in `filenames` wasn’t found.
        RuntimeError: The command `ncrcat` produced an error or the output
            file wasn’t created.
    """
    cprint("Concatenating files to '%s'..." % out_file)
    for f in filelist:
        if not os.path.isfile(f):
            raise FileNotFoundError("Input file not found: '%s'" % f)
    status = subprocess.run(["ncrcat"] + filelist + [out_file])
    if status != 0:
        raise RuntimeError("The command `ncrcat` failed.")
    if not os.path.isfile(out_file):
        raise RuntimeError("The command `ncrcat` didn’t produce an output "
                           "file.")
