from termcolor import cprint
import os
import xarray as xr
import yaml

def calculate_bias(target, source, env):
    """
    Create a file with the monthly bias of TraCE compared to the CRUNCEP data.

    This function is designed as an action for a SCons builder.

    Args:
        target: Bias file.
        source: List of two file names, [trace_file, cru_file].
    """
    (trace_file, cru_file) = source
    bias_file = target

    # Open and load the files completely. They need to be in the RAM for
    # calculation.
    trace = xr.open_dataset(trace_file, decode_times=False).load()
    cru = xr.open_dataset(cru_file, decode_times=False).load()

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

    cprint("Saving bias map to file '%s'." % bias_file, "green")
    bias.to_netcdf(bias_file, mode='w')
    trace.close()
    cru.close()
    bias.close()
    return None  # Return success.
