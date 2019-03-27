import glob
import os
import shutil
import subprocess

import yaml
from termcolor import cprint

from trace_for_guess.skip import skip


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
    if not os.path.isfile(precc_file):
        raise FileNotFoundError("Could not find PRECC file: '%s'" % precc_file)
    if not os.path.isfile(precl_file):
        raise FileNotFoundError("Could not find PRECL file: '%s'" % precl_file)
    if skip([precc_file, precl_file], prect_file):
        return prect_file
    cprint('Adding PRECC and PRECL to PRECT:', 'yellow')
    cprint(f"'{precc_file}' + '{precl_file}' -> '{prect_file}'", 'yellow')
    # First copy PRECC file into output location so that we can rename its
    # variable to match the variable of the other operand. If the names of the
    # variables don’t match, NCO will not be able to add them.
    try:
        shutil.copy(precc_file, prect_file)
        assert(os.path.isfile(prect_file))
        os.chmod(prect_file, 0o666)  # Read/write for everybody
        subprocess.run(['ncrename', '--overwrite', '--variable=PRECC,PRECL',
                        prect_file], check=True)
        # Now we can add the values of the variable "PRECL".
        subprocess.run(['ncbo', '--overwrite', '--op_typ=add', precl_file,
                        prect_file, prect_file], check=True)
        # Finally we need to name the sum appropriately "PRECT".
        subprocess.run(['ncrename', '--variable', 'PRECL,PRECT', prect_file],
                       check=True)
        opts = yaml.load(open('options.yaml'))
        long_name = opts['nc_attributes']['PRECT']['long_name']
        subprocess.run(['ncatted', '--overwrite',
                        '--attribute', f'long_name,PRECT,m,c,"{long_name}"',
                        prect_file], check=True)
        # Convert precipitation flux from m/s to kg/m²/s (compare README).
        subprocess.run(['ncap2', '--overwrite', '--script=PRECT*=1000.0',
                        prect_file, prect_file], check=True)
        units = opts['nc_attributes']['PRECT']['units']
        subprocess.run(['ncatted', '--overwrite',
                        '--attribute', f'units,PRECT,m,c,"{units}"',
                        prect_file], check=True)
    except Exception:
        if os.path.isfile(prect_file):
            cprint(f"Removing file '{prect_file}'.", 'red')
            os.remove(prect_file)
        for f in glob.glob(f'{prect_file}.pid*.tmp'):
            cprint(f"Removing file '{f}'.", 'red')
            os.remove(f)
        raise
    cprint(f"Successfully created '{prect_file}'.", 'green')
    return prect_file
