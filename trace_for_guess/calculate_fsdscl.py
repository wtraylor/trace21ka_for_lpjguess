import glob
import os
import shutil
import subprocess

import xarray as xr
from termcolor import cprint

from trace_for_guess.skip import skip


def calculate_fsdscl(cldtot_file, fsds_file, fsdsc_file, out_file):
    """Re-construct the CCSM3 FSDSCL variable from CLDTOT, FSDS, and FSDSC.

    - FSDS: Downwelling solar flux at surface in W/m².
    - CLDTOT: Vertically-integrated total cloud fraction. This is equivalent to
        the cld variable in the CRU dataset.
    - FSDSC: Incoming radiation with a completely clear sky (zero cloud cover).
    - FSDSCL: Incoming radiation with a completely overcast sky (100% cloud
        cover).

    Args:
        cldtot_file: Path to the CLDTOT input file.
        fsds_file: Path to the FSDS input file.
        fsdsc_file: Path to the FSDSC input file.
        out_file: Path to the FSDSCL output file (to be created).

    Returns:
        The path to the output file (=`out_file`).

    Raises:
        FileNotFoundError: One of the 3 input files is missing.
    """
    if not os.path.isfile(cldtot_file):
        raise FileNotFoundError("Could not find CLDTOT file: '%s'" %
                                cldtot_file)
    if not os.path.isfile(fsds_file):
        raise FileNotFoundError("Could not find FSDS file: '%s'" % fsds_file)
    if not os.path.isfile(fsdsc_file):
        raise FileNotFoundError("Could not find FSDSC file: '%s'" % fsdsc_file)
    # TODO: check for commands
    if skip([cldtot_file, fsds_file, fsdsc_file], out_file):
        return out_file
    cprint(f"Generating FSDSCL file: '{out_file}'", 'yellow')
    try:
        # Merge all variables (FSDS, FSDSC, CLDTOT) into one file, and then
        # perform the operation in it.
        subprocess.run(['ncks', '--append', fsds_file, out_file], check=True)
        subprocess.run(['ncks', '--append', fsdsc_file, out_file], check=True)
        subprocess.run(['ncks', '--append', cldtot_file, out_file], check=True)
        subprocess.run(['ncap2', '--append', '--script',
                        'FSDSCL = FSDS - FSDSC * (1 - CLDTOT) / CLDTOT',
                        out_file], check=True)
    except Exception:
        if os.path.isfile(out_file):
            cprint(f"Removing file '{out_file}'.", 'red')
            os.remove(out_file)
        # Remove temporary file created by ncks.
        for g in glob(f'{out_file}.pid*.ncks.tmp'):
            cprint(f"Removing file '{g}'.", 'red')
            os.remove(g)
        raise
    assert(os.path.isfile(out_file))
    cprint(f"Successfully created '{out_file}'.", 'green')
    return out_file
