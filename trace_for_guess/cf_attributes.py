#!/bin/python

import yaml

def set_attributes(da, var):
    """Set NetCDF attributes to values that LPJ-GUESS expects.

    Args:
        da: xarray.Dataarray object
        var: Variable name as it is defined in `options.yaml`.
    """
    attributes = yaml.load(open("options.yaml"))["nc_attributes"][var]
    for (key,val) in attributes:
        da.attrs[key] = val
    pass
