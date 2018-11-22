#!/bin/bash

mkdir --parents heap/crujra

cdo ymonmean -monstd -cat $(ls heap/crujra_orig/*.nc | sed 's/^/-daysum /') heap/crujra/monthly_std.nc
