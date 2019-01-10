#!/bin/bash

# First copy PRECC file into output location so that we can rename its
# variable, matching the variable of the other operand.
cp "$PRECC" "$PRECT"
ncrename --variable PRECC,PRECL "$PRECT"

# Now we can add the matching variable name "PRECL".
ncbo --overwrite --op_typ='add' -o "$PRECT" "$PRECL" "$PRECT"

# Finally we need to name the sum appropriately "PRECT".
ncrename --variable PRECL,PRECT "$PRECT"

LONG_NAME="Total (convective and large-scale) precipitation rate (liq + ice)"
ncatted --overwrite --attribute long_name,PRECT,m,c,"$LONG_NAME" "$PRECT"
