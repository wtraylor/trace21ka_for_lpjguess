import os
import shutil
import subprocess

from termcolor import cprint

from trace_for_guess.skip import skip


def convert_months_to_days(trace_file, out_file):
    """Convert time unit from 'months since' to 'days since'.

    Args:
        trace_file: File path to TraCE-21ka file with a relative time unit.
        out_file: Path to output file.

    Returns:
        The output file (`out_file`).

    Raises:
        FileNotFoundError: If `trace_file` does not exist.
        RuntimeError: If one of the commands cannot be found in the PATH.
    """
    if not os.path.isfile(trace_file):
        raise FileNotFoundError(f"Could not find TraCE file '{trace_file}'.")
    if skip(trace_file, out_file):
        return out_file
    cprint(f"Converting time unit for LPJ-GUESS in TraCE file '{trace_file}'.",
           'yellow')
    if shutil.which('cdo') is None:
        raise RuntimeError('Executable `cdo` not found.')
    out_dir = os.path.dirname(out_file)
    if not os.path.isdir(out_dir):
        cprint(f"Heap directory '{out_dir}' does not exist yet. I will create "
               "it.", 'yellow')
        os.makedirs(out_dir)
    try:
        subprocess.run(['cdo', 'settunits,days', trace_file, out_file],
                       check=True)
    except Exception:
        if os.path.isfile(out_file):
            cprint(f"Removing file '{out_file}'.", 'red')
            os.remove(trace_file)
        raise
    assert os.path.isfile(out_file)
    cprint(f"Successfully created file: '{out_file}'", 'green')
    return out_file


def convert_kabp_to_months(trace_file, out_file):
    """Convert the default kaBP time unit to 'months since 1-1-15'.

    Args:
        trace_file: File path to TraCE-21ka file with kaBP unit.
        out_file: Path to output file.

    Returns:
        The output file (`out_file`).

    Raises:
        FileNotFoundError: If `trace_file` does not exist.
        RuntimeError: If one of the commands cannot be found in the PATH.
    """
    if not os.path.isfile(trace_file):
        raise FileNotFoundError(f"Could not find TraCE file '{trace_file}'.")
    if skip(trace_file, out_file):
        return out_file
    cprint(f"Converting kaBP time unit in TraCE file '{trace_file}'.",
           'yellow')
    if shutil.which('cdo') is None:
        raise RuntimeError('Executable `cdo` not found.')
    if shutil.which('ncap2') is None:
        raise RuntimeError('Executable `ncap2` not found.')
    if shutil.which('ncatted') is None:
        raise RuntimeError('Executable `ncatted` not found.')
    out_dir = os.path.dirname(out_file)
    if not os.path.isdir(out_dir):
        cprint(f"Heap directory '{out_dir}' does not exist yet. I will create "
               "it.", 'yellow')
        os.makedirs(out_dir)
    try:
        # We leave `trace_file` untouched and change the calendar in a
        # temporary file `tmp_file`.
        tmp_file = out_file + '.tmp'
        # The in-built `date()` function in the TraCE files converts the time
        # to the format 'YYYYMMDD' since 22,000 years BP.
        time_script = 'time=date'
        # --append flag overwrites existing time dimension.
        subprocess.run(['ncap2', '--append', '--script', time_script,
                        trace_file, tmp_file], check=True)
        units = 'day as %Y%m%d.%f'
        subprocess.run(['ncatted', '--overwrite',
                        '--attribute', f'units,time,o,c,{units}',
                        tmp_file], check=True)
        assert os.path.isfile(tmp_file)
        # Now the calendar is set correctly to an absolute format. However,
        # LPJ-GUESS needs it relative. That’s why we copy the file with the CDO
        # flag '-r', which converts an absolute time axis to a relative one.
        # We also change the reference time and calendar in the same pipe
        # because e.g. NCO and XArray cannot read time units with very high
        # reference times (e.g. “days since days since 21601-1-15 00:00:00”).
        # However, “days since 1-1-15 00:00:00” creates problems in
        # `cdo splitsel`: time beyond 997392 days is not parsed.
        # Therefore, we use here “months since”.
        # Since LPJ-GUESS cannot read “months since”, we have to convert it
        # back to “days since 1-1-15 00:00:00” for the final output.
        subprocess.run(['cdo', '-r', 'copy',
                        '-setreftime,1-1-15,00:00:00,months', tmp_file,
                        out_file], check=True)
        assert(os.path.isfile(out_file))
        os.remove(tmp_file)
    except Exception:
        if os.path.isfile(out_file):
            cprint(f"Removing file '{out_file}'.", 'red')
            os.remove(out_file)
        if os.path.isfile(tmp_file):
            cprint(f"Removing file '{tmp_file}'.", 'red')
            os.remove(tmp_file)
        raise
    assert os.path.isfile(out_file)
    cprint(f"Successfully created file: '{out_file}'", 'green')
    return out_file
