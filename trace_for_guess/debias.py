import os

from termcolor import cprint

import xarray as xr
from wet_days import add_wet_days_to_dataset


def debias_trace_file(trace_file, bias_file, out_file):
    """Apply bias-correction to a TraCE-21ka file and add wet days.

    Args:
        out_file: Bias-corrected output file name.
        trace_file: Original TraCE-21ka NetCDF file name.
        bias_file: Name of the NetCDF file with 12 bias values (1 per
        month) per grid cell.

    Returns:
        The name of the new file (equal to `out_file`).

    Raises:
        FileNotFoundError: `trace_file` or `bias_file` doesn’t exist.
        NotImplementedError: The NetCDF variable in the TraCE file is unknown.
        RuntimeError: No output file was produced.
    """
    cprint("Debias TraCE file:", "green")
    cprint("'%s' => '%s'" % (trace_file, out_file), "green")
    if not os.path.isfile(bias_file):
        raise FileNotFoundError("Bias file does not exist: '%s'" % bias_file)
    if not os.path.isfile(trace_file):
        raise FileNotFoundError("Input TraCE file does not exist: '%s'" %
                                trace_file)
    # The TraCE map as xarray Dataset.
    trace = xr.open_dataset(trace_file, decode_times=False)
    # Find the variable in the TraCE file.
    if 'TREFHT' in trace.data_vars:
        var = 'TREFHT'
    elif 'PRECT' in trace.data_vars:
        var = 'PRECT'
    else:
        raise NotImplementedError("Could not find known variable in TraCE"
                                  "file: '%s'." % trace_file)
    # The bias map as xarray Dataset.
    bias = xr.open_dataarray(bias_file, decode_times=False).load()
    # How many years are in the monthly TraCE file?
    years = len(trace[var]) // 12
    # Repeat the monthly bias values for each year.
    bias = xr.concat([bias]*years, dim='time')
    # Overwrite the time dimension. If it does not match the TraCE file, the
    # arithmetic operation does not work.
    bias.time.values = trace.time.values
    # Apply the bias to the TraCE data.
    if var == "TREFHT":
        output = trace[var] + bias
    elif var == "PRECT":
        output = trace[var] * bias
    else:
        raise NotImplementedError("No bias correction defined for variable "
                                  "'%s'." % var)
    # Calculate wet days.
    if var == "PRECT":
        prec_std = xr.open_dataset("heap/crujra/monthly_std_regrid.nc",
                                   decode_times=False)
        add_wet_days_to_dataset(trace, prec_std)
    output.to_netcdf(out_file)
    output.close()
    if not os.path.isfile(out_file):
        raise RuntimeError("No output file created.")
    return out_file
