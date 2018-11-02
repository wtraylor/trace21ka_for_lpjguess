#!/bin/bash

# Arguments:
# 1) PRECC (input)
# 2) PRECL (input)
# 3) PRECT (output)

# Exit on failure of any command.
set -e

echo "Adding PRECC and PRECL to PRECT:"
echo -e "  '$1'\n+ '$2'\n= '$3'"

PRECC="$1"
PRECL="$2"
PRECT="$3"

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
