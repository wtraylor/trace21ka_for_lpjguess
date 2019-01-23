import os
import shutil
import subprocess

import yaml
from termcolor import cprint


def add_precc_and_precl_to_prect(precc_file, precl_file, prect_file):
    """Build sum of the TraCE variables PRECC and PRECL using NCO commands.

    PRECC is convective precipitation, PRECL is the local precipitation, and
    PRECT is the sum of both: the total precipitation.

    Args:
        precc_file: The TraCE-21ka NetCDF file with the PRECC variable.
        precl_file: The TraCE-21ka NetCDF file with the PRECL variable.
        prect_file: The output file (will *not* be overwritten).

    Returns:
        The PRECT file (=`prect_file`).

    Raises:
        FileNotFoundError: Either the PRECC or the PRECL file couldn’t be
            found.
        RuntimeError: The `ncrename` command has failed or produced not output.
    """
    cprint("Adding PRECC and PRECL to PRECT: '%s'" % prect_file, 'yellow')
    if not os.path.isfile(precc_file):
        raise FileNotFoundError("Could not find PRECC file: '%s'" % precc_file)
    if not os.path.isfile(precl_file):
        raise FileNotFoundError("Could not find PRECL file: '%s'" % precl_file)
    if os.path.isfile(prect_file):
        cprint(f"Skipping: '{prect_file}'", 'cyan')
        return prect_file
    # First copy PRECC file into output location so that we can rename its
    # variable to match the variable of the other operand.
    try:
        shutil.copy2(precc_file, prect_file)
        assert(os.path.isfile(prect_file))
        subprocess.run(['ncrename', '--variable PRECC,PRECL', prect_file],
                       check=True)
    except:
        if os.path.isfile(prect_file):
            cprint(f"Removing file '{prect_file}'.", 'red')
            os.remove(prect_file)
        raise
    # Now we can add the matching variable name "PRECL".
    try:
        subprocess.run(['ncbo', '--op_typ=add', f'-o {prect_file}', precl_file,
                        prect_file], check=True)
    except:
        if os.path.isfile(prect_file):
            cprint(f"Removing file '{prect_file}'.", 'red')
            os.remove(prect_file)
        raise
    # Finally we need to name the sum appropriately "PRECT".
    try:
        subprocess.run(['ncrename', '--variable PRECL,PRECT', prect_file],
                       check=True)
    except:
        if os.path.isfile(prect_file):
            cprint(f"Removing file '{prect_file}'.", 'red')
            os.remove(prect_file)
        raise
    long_name = yaml.load(
        open('options.yaml'))['nc_attributes']['prec']['long_name']
    try:
        subprocess.run(['ncatted', '--overwrite',
                        f'--attribute long_name,PRECT,m,c,"{long_name}"',
                        prect_file], check=True)
    except:
        if os.path.isfile(prect_file):
            cprint(f"Removing file '{prect_file}'.", 'red')
            os.remove(prect_file)
        raise
    cprint(f"Successfully created '{prect_file}'.", 'green')
    return prect_file
