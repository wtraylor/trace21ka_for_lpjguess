from termcolor import cprint
from subprocess import run


def add_precc_and_precl_to_prect(precc_file, precl_file, prect_file):
    """Build sum of variable PRECC and PRECL.
    """
    cprint("Adding PRECC and PRECL to PRECT: '%s'" % prect_file, "green")
