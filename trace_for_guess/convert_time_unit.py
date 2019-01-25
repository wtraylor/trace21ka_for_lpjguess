import os
import shutil
import subprocess

import xarray as xr
import yaml
from termcolor import cprint


def convert_time_unit(trace_file):
    """Convert kaBP time unit to calendar using NCO commands.

    Args:
        trace_file: File path to TraCE-21ka file with kaBP unit.

    Raises:
        FileNotFoundError: If `trace_file` does not exist.
    """
    if not os.path.isfile(trace_file):
        raise FileNotFoundError(f"Could not find TraCE file '{trace_file}'.")
    attrs = yaml.load(open('options.yaml'))['nc_attributes']['time']
    with xr.open_dataset(trace_file, decode_times=False) as ds:
        if ds.time.attrs['calendar'] == attrs['calendar']:
            cprint(f"Time unit already converted: '{trace_file}'", 'cyan')
            return
    cprint(f"Converting kaBP time unit in TraCE file '{trace_file}'.",
           'yellow')
    if shutil.which('ncatted') is None:
        raise RuntimeError("Executable `ncatted` not found.")
    if shutil.which('ncap2') is None:
        raise RuntimeError("Executable `ncap2` not found.")
    try:
        time_script = 'time=trunc((time+22.0)*1000*365)'
        # --append flag overwrites existing time dimension.
        subprocess.run(['ncap2', '--append', '--script', time_script,
                        trace_file], check=True)
        units = attrs['units']
        calendar = attrs['calendar']
        subprocess.run(['ncatted', '--overwrite',
                        '--attribute', f'units,time,o,c,{units}',
                        '--attribute', f'calendar,time,o,c,{calendar}',
                        trace_file], check=True)
    except Exception:
        cprint(f"Removing file '{trace_file}'.", 'red')
        os.remove(trace_file)
