#!/bin/bash

## Echo in green color
function green() {
  # Here, we use the system’s `tput` command because Miniconda also contains
  # one, but that creates errors.
  /usr/bin/tput setaf 2
  (>&2 echo -e $*)
  /usr/bin/tput sgr0
}

mkdir --parents heap/crujra

green "Calculating day-to-day standard deviation of precipitation,"
green "using the following files:"
echo  "$CRUJRA_UNZIPPED" | sed 's/\s\s*/\n\t/g'

cdo ymonmean -monstd -cat $(echo ${CRUJRA_UNZIPPED} | sed 's/\s\s*/ -daysum /') heap/crujra/monthly_std.nc
