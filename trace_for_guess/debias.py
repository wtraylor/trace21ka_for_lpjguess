import os

import xarray as xr
from termcolor import cprint

from trace_for_guess.skip import skip


def debias_trace_file(trace_file, bias_file, out_file):
    """Apply bias-correction to a TraCE-21ka file and add wet days.

    Args:
        trace_file: Original TraCE-21ka NetCDF file name.
        bias_file: Name of the NetCDF file with 12 bias values (1 per
            month) per grid cell.
        out_file: Bias-corrected output file name (will not be overwritten).

    Returns:
        The name of the new file (equal to `out_file`).

    Raises:
        FileNotFoundError: `trace_file` or `bias_file` doesn’t exist.
        NotImplementedError: The NetCDF variable in the TraCE file is unknown.
        RuntimeError: No output file was produced.
    """
    if not os.path.isfile(bias_file):
        raise FileNotFoundError("Bias file does not exist: '%s'" % bias_file)
    if not os.path.isfile(trace_file):
        raise FileNotFoundError("Input TraCE file does not exist: '%s'" %
                                trace_file)
    if skip([bias_file, trace_file], out_file):
        return out_file
    out_dir = os.path.dirname(out_file)
    if not os.path.isdir(out_dir):
        cprint(f"Directory '{out_dir}' does not exist yet. I will create it.",
               'yellow')
        os.makedirs(out_dir)
    cprint(f"Debiasing TraCE file '{trace_file}'...", 'yellow')
    try:
        with xr.open_dataset(trace_file, decode_times=False) as trace:
            # Find the variable in the TraCE file.
            if 'TREFHT' in trace.data_vars:
                var = 'TREFHT'
            elif 'PRECT' in trace.data_vars:
                var = 'PRECT'
            else:
                raise NotImplementedError("Could not find known variable in "
                                          "TraCE file: '%s'." % trace_file)
            # The bias map as xarray Dataset.
            bias = xr.open_dataarray(bias_file, decode_times=False).load()
            # How many years are in the monthly TraCE file?
            years = len(trace[var]) // 12
            # Repeat the monthly bias values for each year.
            bias = xr.concat([bias]*years, dim='time')
            # Overwrite the time dimension. If it does not match the TraCE
            # file, the arithmetic operation does not work.
            bias.time.values = trace.time.values
            # Apply the bias to the TraCE data.
            if var == "TREFHT":
                output = trace[var] + bias
            elif var == "PRECT":
                output = trace[var] * bias
            else:
                raise NotImplementedError("No bias correction defined for "
                                          "variable '%s'." % var)
            output.to_netcdf(out_file, mode='w', engine='netcdf4')
    except:
        if os.path.isfile(out_file):
            cprint(f"Removing file '{out_file}'.", 'red')
            os.remove(out_file)
        raise
    assert os.path.isfile(out_file), f"No output file created: '{out_file}'"
    cprint(f"Successfully created '{out_file}'.", 'green')
    return out_file
