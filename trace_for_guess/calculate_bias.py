import os

from termcolor import cprint

import xarray as xr


def calculate_bias(trace_file, trace_var, cru_file, cru_var, bias_file):
    """Create a file with the monthly bias of TraCE compared to the CRUNCEP data.

    Each of the input files should contain only 12 values per grid cell
    (one average per month).

    Args:
        trace_file: The TraCE-21ka NetCDF file with modern monthly averages.
        trace_var: NetCDF variable in the TraCE file.
        cru_file: The CRU NetCDF file with modern monthly averages.
        cru_var: NetCDF variable in the CRU file.
        bias_file: Path to output file (will not be overwritten).

    Returns:
        Path to output file (equals `bias_file`).

    Raises:
        FileNotFoundError: The file `trace_file` or `cru_file` wasn’t found.
        NotImplementedError: The variable in the TraCE file is not
            implemented.
    """
    if not os.path.isfile(trace_file):
        raise FileNotFoundError(
            "TraCE-21ka mean file doesn’t exist: '%s'" % trace_file)
    if not os.path.isfile(cru_file):
        raise FileNotFoundError("CRU mean file doesn’t exist: '%s'" % cru_file)
    if os.path.isfile(bias_file):
        cprint(f"Skipping: '{bias_file}'", 'cyan')
        return bias_file
    cprint('Calculating bias:', 'yellow')
    cprint(f"'{trace_file}' x '{cru_file}' -> '{bias_file}'", 'yellow')
    # Open and load the files completely. They need to be in the RAM for
    # calculation.
    trace = xr.open_dataset(trace_file, decode_times=False).load()
    cru = xr.open_dataset(cru_file, decode_times=False).load()
    try:
        # The values of the 'time' dimensions of the CRU and the TraCE dataset
        # must match in order to perform calculation. So we just overwrite the
        # values with 0 to 11 as the month numbers, assuming that the CRU
        # record also starts with January.
        cru["time"].values = [i for i in range(12)]
        # Rename the variable in the CRU file to the TraCE variable name.
        cru = cru.rename({cru_var: trace_var})
        if trace_var == "TREFHT":
            bias = trace[trace_var] - cru[trace_var]
        elif trace_var == "PRECT":
            # TODO Rename precipitation variable
            bias = trace[trace_var] / cru[trace_var]
        else:
            raise NotImplementedError("Arithmetic operation not defined for"
                                      "variable '%s'." % trace_var)
            bias.to_netcdf(bias_file, mode='w')
        bias.close()
    except:
        if os.path.isfile(bias_file):
            cprint(f"Removing file '{bias_file}'.", 'red')
            bias.close()
            os.remove(bias_file)
    finally:
        trace.close()
        cru.close()
    assert(os.path.isfile(bias_file))
    cprint(f"Successfully created '{bias_file}'.", 'green')
    return bias_file
