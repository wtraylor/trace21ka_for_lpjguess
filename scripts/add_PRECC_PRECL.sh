#!/bin/bash

# Arguments:
# 1) PRECC (input)
# 2) PRECL (input)
# 3) PRECT (output)

# Exit on failure of any command.
set -e

# Add PRECL and PRECC to PRECT.
echo "Adding PRECC and PRECL to PRECT:"
echo "'$1' + '$2' = '$3'"
ncbo --overwrite --op_typ='add' "$1" "$2" "$3"

echo "Renaming the variable to 'PRECT'."
ncrename --variable PRECL,PRECT "$3"

echo "Updating the 'long_name' attribute."
LONG_NAME="Total (convective and large-scale) precipitation rate (liq + ice)"
ncatted --overwrite --attribute long_name,PRECT,m,c,"$LONG_NAME" "$3"
