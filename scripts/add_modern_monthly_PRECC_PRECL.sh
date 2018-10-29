#!/bin/bash

# Exit on failure of any command.
set -e

# Add PRECL and PRECC to PRECT.
echo "Adding modern PRECC and PRECL to PRECT."
ncbo \
  --overwrite \
  --op_typ='add' \
  $(HEAP)/modern_trace_PRECL.nc \
  $(HEAP)/modern_trace_PRECC.nc \
  $(HEAP)/modern_trace_PRECT.nc

echo "Renaming the variable to 'PRECT'."
ncrename \
  --variable PRECL,PRECT \
  $(HEAP)/modern_trace_PRECT.nc

echo "Updating the 'long_name' attribute."
ncatted \
  --overwrite \
  --attribute long_name,PRECT,m,c,"Total (convective and large-scale) precipitation rate (liq + ice)" \
  $(HEAP)/modern_trace_PRECT.nc
