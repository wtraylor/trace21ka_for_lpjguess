#! /bin/bash
################################################################################
# GLOBAL SETTINGS FOR MY TRACE-21KA INPUT IN LPJ-GUESS
# Wolfgang Pappa, 22.05.2016
################################################################################
################################################################################
################################################################################


################################################################################
# SIMULATION SETTINGS
################################################################################
# make sure first year is chronologically before last year!
# The whole TraCE-21ka dataset stretches from 22000 years BP to 0 BP (=1950 AD)
export FIRSTYEAR=22000 # BP [22000,0]
export LASTYEAR=11000 # BP [22000,0]

# The year for which sea level and glacier data is read from ICE-5G to 
# produce gridcell list
export ICE5G_MASK_YEAR=21000 # must be in between 0 and 21000 

export ICE5G_MASK_OCEANS="TRUE" # whether to exclude ICE5G water from gridcells
export ICE5G_MASK_GLACIERS="FALSE" # whether to exclude ICE5G glaciers from gridcells

# extent of study area (longitude[0.0,360.0], latitude[-90.0,90.0])
# The decimal points are important for ncks hyperslabbing (cropping)
export LONGITUDE_1=130.0
export LONGITUDE_2=230.0
export LATITUDE_1=50.0
export LATITUDE_2=80.0


################################################################################
# DIRECTORIES AND FILE LOCATIONS
################################################################################

# Directory with ICE5G netCDF files 
export ICE5G_DIR="$HOME/guess_data/ice5g/"

# Directory with TraCE21ka monthly netCDF files 
export TRACE_GLOBAL_DIR="${HOME}/guess_data/trace/global/"
export TRACE_CROPPED_DIR="$HOME/guess_data/trace/cropped/"
export TRACE_LPJ_DIR="$HOME/guess_data/input/trace/"

# Directory with script files for TraCE processing
# Have all the script files there!
export SCRIPT_DIR="$HOME/Masterarbeit/data_processing/trace_for_guess/"

# File with soil data (will be written into the ins script, otherwise not needed
export LPJ_FILE_CRU="$HOME/guess_data/input/cru_1901_2006.bin"

# directory with .ins files for LPJ-GUESS
export LPJ_INS_DIR="$HOME/guess/ins/"
# .ins file for LPJ-GUESS defining the filenames
export LPJ_FILE_INS=${LPJ_INS_DIR}"trace_files.ins"


# Names for the Outpt netCDF files
export LPJ_FILE_SOLIN="${TRACE_LPJ_DIR}lpj_trace21ka_insolation_${FIRSTYEAR}-${LASTYEAR}BP.nc"
export LPJ_FILE_PRECT="${TRACE_LPJ_DIR}lpj_trace21ka_precipitation_${FIRSTYEAR}-${LASTYEAR}BP.nc"
export LPJ_FILE_TREFHT="${TRACE_LPJ_DIR}lpj_trace21ka_temperature_${FIRSTYEAR}-${LASTYEAR}BP.nc"


# The netCDF file to read the list of gridcells from
export GRIDLIST_REFERENCE_FILE=$LPJ_FILE_TREFHT

# Compose name for gridcells file
LPJ_FILE_GRIDLIST="${TRACE_LPJ_DIR}trace21ka_gridlist"
# Input files for LPJ-GUESS = Output files of TraCE processing
if [ $ICE5G_MASK_GLACIERS = "TRUE" -o $ICE5G_MASK_OCEANS = "TRUE" ]; then
	LPJ_FILE_GRIDLIST+="_ice5g_"$ICE5G_MASK_YEAR"BP"
	[ $ICE5G_MASK_GLACIERS = "TRUE" ] && LPJ_FILE_GRIDLIST+="_unglaciated"
	[ $ICE5G_MASK_OCEANS = "TRUE" ] && LPJ_FILE_GRIDLIST+="_land"
fi
LPJ_FILE_GRIDLIST+=".txt"
export LPJ_FILE_GRIDLIST

# The netCDF file to read the CO₂ values from
export CO2_REFERENCE_FILE=$LPJ_FILE_TREFHT

# The text file to write the CO₂ values into
export LPJ_FILE_CO2="${TRACE_LPJ_DIR}co2_${FIRSTYEAR}-${LASTYEAR}BP.txt"


################################################################################
### VARIABLES AND ATTRIBUTES
################################################################################

# Variable names in the new output netCDF files for LPJ-GUESS
# Can be customized as desired
export LPJ_VAR_SOLIN="SOLIN"
export LPJ_VAR_PRECT="PRECT"
export LPJ_VAR_TREFHT="TREFHT"

# Variable standard_names in the output files for LPJ-GUESS
# Don't change these because the CF input module of LPJ-GUESS needs the 
# exact string match.
export CF_STANDARD_NAME_SOLIN="surface_net_downward_shortwave_flux"
export CF_STANDARD_NAME_TREFHT="air_temperature"
export CF_STANDARD_NAME_PRECT="precipitation_flux"
export CF_STANDARD_NAME_LAT="latitude"
export CF_STANDARD_NAME_LON="longitude"
export CF_UNIT_SOLIN="W m-2"
export CF_UNIT_TREFHT="K"
export CF_UNIT_PRECT="kg m-2 s-1"
export CF_UNIT_LAT="degrees_north"
export CF_UNIT_LON="degrees_east"


################################################################################
### TIME AND CALENDAR
################################################################################

# A note on calendar and time:
# TraCE-21ka uses decimal negative ka BP (thousand years before present, i.e. 
# 1950) values as time.
# The CF standard requires days as unit.
# LPJ-GUESS follows ISO 8601, asking for a calendar year, i.e. relative to
# BC/AD (birth of Christ) and not BP.
# The time of the TraCE files is recalculated accordingly as days since
# -(22000-1950) = -20050

# The following script is passed to ncap2 to perform that calculation:
export TIME_SCRIPT="time=trunc((time+22.0)*1000*365)"

export TRACE_START_CALENDAR_YEAR="-20050" # First entry in TraCE dataset [years AD]
export CF_UNIT_TIME="days since ${TRACE_START_CALENDAR_YEAR}-1-1 0:0:0"
export CF_CALENDAR="365_day" # All years are 365 days long; equivalent to "noleap"	


################################################################################
### VARIABLES FOR OTHER SCRIPTS OF TRACE PROCESSING
### not used for prepare_trace_for_lpj.sh
################################################################################
export TRACE_ANALYSIS_DIR="$HOME/guess_data/trace/analysis/" 
export TRACE_TIMELINE=${TRACE_ANALYSIS_DIR}"trace_timeline.nc"
export TRACE_TMAX_MAP=${TRACE_ANALYSIS_DIR}"trace_TMAX_map.nc"
export TRACE_TMIN_MAP=${TRACE_ANALYSIS_DIR}"trace_TMIN_map.nc"
export TRACE_PREC_MAP=${TRACE_ANALYSIS_DIR}"trace_PRECT_map.nc"

export TRACE_TREFHT_CONCAT=${TRACE_ANALYSIS_DIR}"TREFHT_concat.nc"
export TRACE_PRECT_CONCAT=${TRACE_ANALYSIS_DIR}"PRECT_concat.nc"
export TRACE_SOLIN_CONCAT=${TRACE_ANALYSIS_DIR}"SOLIN_concat.nc"

# modern temperatures:
export TRACE_TREFHT_1990="$HOME/guess_data/trace/trace.36.400BP-1990CE.cam2.h0.TREFHT.2160101-2204012.nc" 
# modern precipitation:
export TRACE_PRECT_1990="$HOME/guess_data/trace/trace.36.400BP-1990CE.cam2.h0.PRECT.2160101-2204012.nc" 


# Record index of first summer month (0=January)
export TMAX_MONTH_INDEX=6 # July
# Record index of first winter month (0=January)
export TMIN_MONTH_INDEX=0 # January

# Sample locations:
export LAT_ALASKA=65.0 
export LON_ALASKA=200.0

# Output directory of the simulation
export LPJ_OUTPUT_DIR="$HOME/guess_data/output/"

################################################################################
# Set the flag that the environment variables are set

export TRACE_VARIABLES_SET="TRUE"
