import os.path
import shutil
from termcolor import cprint
from subprocess import run


def add_precc_and_precl_to_prect(precc_file, precl_file, prect_file):
    """Build sum of the TraCE variables PRECC and PRECL using NCO commands.

    PRECC is convective precipitation, PRECL is the local precipitation, and
    PRECT is the sum of both: the total precipitation.

    Args:
        precc_file: The TraCE-21ka NetCDF file with the PRECC variable.
        precl_file: The TraCE-21ka NetCDF file with the PRECL variable.
        prect_file: The output file.

    Returns:

    Raises:
        FileNotFoundError: Either the PRECC or the PRECL file couldn’t be
            found.
        RuntimeError: The `ncrename` command has failed or produced not output.
    """
    cprint("Adding PRECC and PRECL to PRECT: '%s'" % prect_file, "green")
    if not os.path.isfile(precc_file):
        raise FileNotFoundError("Could not find PRECC file: '%s'" % precc_file)
    if not os.path.isfile(prect_file):
        raise FileNotFoundError("Could not find PRECT file: '%s'" % prect_file)
    # First copy PRECC file into output location so that we can rename its
    # variable to match the variable of the other operand.
    shutil.copy2(precc_file, prect_file)
    run("ncrename", "--variable PRECC,PRECL", prect_file)
    # Now we can add the matching variable name "PRECL".
    ncbo --overwrite --op_typ='add' -o "$PRECT" "$PRECL" "$PRECT"

