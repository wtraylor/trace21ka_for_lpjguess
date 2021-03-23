# SPDX-FileCopyrightText: 2021 Wolfgang Traylor <wolfgang.traylor@senckenberg.de>
#
# SPDX-License-Identifier: MIT

import os
import shutil
import subprocess

from termcolor import cprint

from trace_for_guess.skip import skip


def rescale_file(in_file, out_file, template_file, alg):
    """Regrid a NetCDF file using NCO (i.e. the ncremap command).

    Args:
        in_file: Path of input file.
        out_file: Output file path. It will not be overwritten.
        template_file: Path to a NetCDF file that has the desired grid
            resolution.
        alg: ESMF regrid algorithm. See here:
            http://www.earthsystemmodeling.org/esmf_releases/public/ESMF_6_3_0rp1/ESMF_refdoc/node3.html#SECTION03020000000000000000

    Returns:
        The output file (`out_file`).

    Raises:
        FileNotFoundError: If `in_file` or `template_file` doesn’t exist.
        RuntimeError: The `cdo` command is not in the PATH.
        RuntimeError: The `ncremap` command failed or produced no output
            file.
    """
    if not os.path.isfile(in_file):
        raise FileNotFoundError("Input file doesn’t exist: '%s'" % in_file)
    if not os.path.isfile(template_file):
        raise FileNotFoundError("Template file doesn’t exist: '%s'" %
                                template_file)
    if skip([in_file, template_file], out_file):
        return out_file
    if shutil.which("ncremap") is None:
        raise RuntimeError("Executable `ncremap` not found.")
    cprint("Regridding '%s'..." % in_file, 'yellow')
    try:
        subprocess.run(["ncremap",
                        "--algorithm=%s" % alg,
                        "--template_file=%s" % template_file,
                        "--input_file=%s" % in_file,
                        "--output_file=%s" % out_file], check=True)
    except Exception:
        if os.path.isfile(out_file):
            cprint(f"Removing file '{out_file}'.", 'red')
            os.remove(out_file)
        raise
    if not os.path.isfile(out_file):
        raise RuntimeError("Regridding with `ncremap` failed: No output file "
                           "created.")
    cprint(f"Successfully created '{out_file}'.", 'green')
    return out_file
