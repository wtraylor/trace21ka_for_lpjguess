#! /bin/bash
###############################################################################
## Bash script to prepare TraCE-21ka netCDF files for LPJ-GUESS
## Wolfgang Pappa, 22.05.2016
###############################################################################

function print_use {
################################################################################
########        HELP AND INTRODUCTION TEXT                    #################
################################################################################
echo
echo "**** TraCE-21ka for LPJ-GUESS ****"
echo "This is a script to prepare TraCE-21ka monthly paleoclimate files for LPJ-GUESS:"
echo -e "\t– Crop files to given region and place them into the folder for cropped files."
echo -e "\t– Calculate total precipitation (PRECT) from convective (PRECC) and large-scale (PRECL) precipitation."
echo -e "\t– Concatenate files to one netCDF file for each precipitation, temperature, and insolation."
echo -e "\t- Crop the concatenated files to given time frame."
echo -e "\t– Adjust time to calendar years."
echo -e "\t– Change metadata in the produced files to comply with LPJ-GUESS."
echo -e "\t– Adjust latitude values to ‘nicer’ values (i.e. truncating the long tail of odd decimal values)."
echo -e "\t– Create gridcell list using ICE-5G data to exclude ocean and/or glaciers from simulation."
echo -e "\t- Create a CO₂ text file."
echo -e "\t– Generate an .ins file for LPJ-GUESS with the correct paths and variable names."
echo
echo "System requirements:"
echo -e "\t– Have TraCE-21ka data downloaded (monthly data for variables: $TRACE_VAR):"
echo -e "\t  https://www.earthsystemgrid.org/dataset/ucar.cgd.ccsm3.trace.html"
echo -e "\t– Have ICE-5G data downloaded (if gridcells shall be masked with them): "
echo -e "\t  https://pmip2.lsce.ipsl.fr/design/ice5g/"
echo -e "\t– Have all variables set up in trace_settings.sh"
echo -e "\t– nco must be installed: http://nco.sourceforge.net/"
echo -e "\t– R must be installed: http://r-project.org/"
echo -e "\t  required packages: ncdf4, raster"
echo
}

function print_time_range {
	echo -n "$(ncks --units -H -v time -d time,0,0 $1) – $(ncks --units -H -v time -d time,-1,-1 $1)"
}

################################################################################
########        PREPARATION OF VARIABLES                      #################
################################################################################
# Generally we iterate over the list of netCDF-Variables (SOLIN etc) 
# Bash variables referring to these are created with a suffix like ORIGINAL_FILES_SOLIN

# Variable names in the TraCE input files (don’t customize this)
TRACE_VAR=("SOLIN" "PRECC" "PRECL" "TREFHT") # needed as input
LPJ_VAR=("SOLIN" "PRECT" "TREFHT") # needed as output


################################################################################
print_use

################################################################################
#                  CHECK SYSTEM REQUIREMENTS ETC.          #####################
################################################################################


TRACE_SETTINGS_SCRIPT="./trace_settings.sh"
if ( type -P $TRACE_SETTINGS_SCRIPT &>/dev/null ); then
	echo "Found $TRACE_SETTINGS_SCRIPT. Executing it to set environment variables..."
	. $TRACE_SETTINGS_SCRIPT
fi

if [[ "$TRACE_VARIABLES_SET" != "TRUE" ]]; then
	echo "Make sure you have set the environment variables in trace_settings.sh"
	echo "e.g. by executing  ». ./trace_settings.sh« before in this shell"
	echo "exiting"
	exit 0
fi

echo "Settings from environment variables:"
echo -e "\tRegion: $LONGITUDE_1–$LONGITUDE_2°E\t$LATITUDE_1–$LATITUDE_2°N"
echo -e "\tTime range: $FIRSTYEAR–$LASTYEAR years BP"
echo -e "\tReference time for ICE-5G mask: $ICE5G_MASK_YEAR years BP"
echo -e "\tMask glaciers from gridcell list: $ICE5G_MASK_GLACIERS"
echo -e "\tMask oceans from gridcell list: $ICE5G_MASK_OCEANS"

## We assume that all custom scripts are in the same directory $SCRIPT_DIR
REQUIRED_SCRIPTS=(
	"get_trace_time_indices.r" 
	"create_ice5g_gridlist.r"
	"create_trace_co2.r"
	"trunc_trace_lat.nco"
	"get_trace_first_lat.nco"
	"get_trace_lat_res.nco"
)
for cmd in ${REQUIRED_SCRIPTS[@]}; do
	if [[ ! -f "${SCRIPT_DIR}$cmd" ]]; then
		echo "R script ${SCRIPT_DIR}$cmd not found."; 
		exit $EXIT_FAILURE
	fi
done

REQUIRED_CMDS=(
	"ncatted"
	"ncks"
	"ncrcat"
	"ncrename"
	"Rscript"
)
for cmd in ${REQUIRED_CMDS[@]}; do
	if ( ! type -P $cmd &>/dev/null ); then
		echo "command $cmd found, please install it" 
		exit $EXIT_FAILURE
	fi
done



################################################################################
########        SEARCH FOR INPUT FILES                        #################
################################################################################

for var in ${TRACE_VAR[@]}; do
	eval "unset ORIGINAL_FILES_$var"
	echo "Searching for input files with variable ›$var‹..."
	
	eval "ORIGINAL_FILES_$var=\$(find ${TRACE_GLOBAL_DIR}trace*${var}*12.nc  2>/dev/null)"
	eval "FILES=\${ORIGINAL_FILES_${var}[@]}"
	if [[ ${#FILES} -eq 0 ]]; then
		echo "No TraCE-21ka input files for variable $var found in »$TRACE_GLOBAL_DIR«"
		echo "Please download them from https://www.earthsystemgrid.org/dataset/ucar.cgd.ccsm3.trace.html"
		exit $EXIT_FAILURE
	else
		for f in ${FILES[@]}; do
			echo -e "\t»$f«"
		done
	fi
done

unset ICE5G_FILES
if [ $ICE5G_MASK_GLACIERS = "TRUE" -o $ICE5G_MASK_OCEANS = "TRUE" ]
then
	ICE5G_FILES=$(find ${ICE5G_DIR}"ice5g_v1.2_"*"k_1deg.nc" 2>/dev/null)
	if [[ ${#ICE5G_FILES} -eq 0 ]]; then
		echo "No ICE-5G files found in »${ICE5G_DIR}«"
		echo "Please download them from https://pmip2.lsce.ipsl.fr/design/ice5g/"
		exit $EXIT_FAILURE
	fi
	echo "Found the following ICE-5G input files:"
	for f in ${ICE5G_FILES[@]}; do
		echo -e "\t»$f«"
	done
fi


################################################################################
########        PREPARATION OF FILES AND DIRECTORIES          #################
################################################################################

# 
# unset DELETE
# # find cropped files from previous runs
# DELETE+=($(find ${TRACE_CROPPED_DIR} -type f -name *.nc 2>/dev/null))
# 
# # All output files
# LPJ_FILES=($LPJ_FILE_SOLIN \
# $LPJ_FILE_PRECT \
# $LPJ_FILE_TREFHT \
# $LPJ_FILE_GRIDLIST \
# $LPJ_FILE_CO2 \
# $LPJ_FILE_INS)
# for f in ${LPJ_FILES[@]}; do
# 	[ -f $f ] && DELETE+=($f)
# done
# 
# if [ ! ${#DELETE[@]} -eq 0 ]; then
# 	echo "Deleting existing files:"
# 	for f in ${DELETE[@]}; do
# 		echo -e "\t»$f«"
# 	done
# 	read -p "Proceed?[y/n]" -n 1 -r
# 	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
# 		echo "User aborted. Please make sure that the directory for cropped files is empty."
# 		exit 1
# 	fi
# 	echo
# 	echo "Deleting files..."
# 	for f in ${DELETE[@]}; do
# 		rm -fr "$f"
# 	done
# 	echo 
# fi

echo
if [ ! -d "$TRACE_LPJ_DIR" ]; then
	echo "Creating directory »${TRACE_LPJ_DIR}«..."
	mkdir -p ${TRACE_LPJ_DIR}
fi
if [ ! -d "${TRACE_CROPPED_DIR}" ]; then
	echo "Creating directory »${TRACE_CROPPED_DIR}«..."
	mkdir -p ${TRACE_CROPPED_DIR}
fi
echo


################################################################################
# CROP REGION 
# crop all files with .nc ending from the the original TraCE-21ka folder
# and put them into the cropped folder (overwriting existing files)
################################################################################

echo
echo "**************** CROP REGION ******************"
echo -e "Longitude:\t$LONGITUDE_1 – $LONGITUDE_2 degrees East"
echo -e "Latitude:\t$LATITUDE_1 – $LATITUDE_2 degrees North"
for var in ${TRACE_VAR[@]}; do
	echo "Variable $var:"
	eval "unset CROPPED_FILES_$var"
	eval "FILES=\${ORIGINAL_FILES_${var}[@]}"
	for IN in ${FILES[@]}; do
		echo "»$IN«"
		# Output filename is similar to input file name
		OUT=${TRACE_CROPPED_DIR}${IN##*/} 
		eval "CROPPED_FILES_$var+=($OUT)"
		
		if [ -f "$OUT" ]; then
			echo -e "\tOutput file »$OUT« already exists."
			read -p "Overwrite it? [y/n]" -n 1 -r
			if [[ ! $REPLY =~ ^[Yy]$ ]]; then
				echo -e "\t->Skipped."
				continue
			fi
		fi
		# $OUT does not exist yet
		echo -e "\t->Cropping..."		
		ncks -O -d lon,${LONGITUDE_1},${LONGITUDE_2} -d lat,${LATITUDE_1},${LATITUDE_2} "$IN" "$OUT"
		
		[ -f "$OUT" ] && echo -e "\t->Written to:»$OUT«"
		
	done
	echo
done

echo
echo "The following cropped files are available:"
for var in ${TRACE_VAR[@]}; do
	eval "FILES=\${CROPPED_FILES_${var}[@]}"
	for f in ${FILES[@]}; do
		echo -e "\t»$f«"
	done
done


################################################################################
# CREATE TOTAL PRECIPITATION (PRECC+PRECL)
################################################################################
echo
echo "**************** PRECT=PRECC+PRECL ******************"
echo "Creating new files for total precipitation: PRECT=PRECC+PRECL..."
unset CROPPED_FILES_PRECT
for PRECL_FILEPATH in ${CROPPED_FILES_PRECL[@]}
do
	PRECL_FILENAME=${PRECL_FILEPATH##*/} # extract the filename
	
	# the corresponding PRECC file should look like this:
	# replace all substrings 'PRECL' with 'PRECC'
	PRECC_FILENAME=${PRECL_FILENAME//"PRECL"/"PRECC"}
	PRECC_FILEPATH=${TRACE_CROPPED_DIR}$PRECC_FILENAME
	# the output filename
	PRECT_FILENAME=${PRECL_FILENAME//"PRECL"/"PRECT"} 
	PRECT_FILEPATH=${TRACE_CROPPED_DIR}$PRECT_FILENAME
	
	echo "PRECT file:»$PRECT_FILEPATH«"
	if [[ -f "$PRECT_FILEPATH" ]]; then
		echo -en "\t->File already exists. Overwrite it? [y/n]"
		read -n 1 -r
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			echo -e "\t->Skipped"
			CROPPED_FILES_PRECT+=($PRECT_FILEPATH)
			continue
		fi
	fi
	
	if [[ -f "$PRECC_FILEPATH" ]] # if the corresponding PRECC file exists
	then 
		echo -e "\tPRECC:»$PRECC_FILENAME«"
		echo -e "\tPRECL:»$PRECL_FILENAME«"
		
		# For ncbo to be able to add PRECC+PRECL, the variable names
		# of both input files need to match. That’s why we 
		# change it in the PRECC file to 'PRECL'.
		echo -e "\tRenaming variable PRECC in »$PRECC_FILENAME« to PRECL to perform calculation."
		ncrename -v PRECC,PRECL $PRECC_FILEPATH 1>/dev/null

		echo -e "\tCreating new PRECT file: »$PRECT_FILENAME«..."
		# Create the PRECT file (-O is overwrite mode)
		ncbo -O --op_typ='+' "$PRECL_FILEPATH" "$PRECC_FILEPATH" "$PRECT_FILEPATH"
		
		if [[ -f "$PRECT_FILEPATH" ]]; then
			CROPPED_FILES_PRECT+=($PRECT_FILEPATH)
			
			echo -e "\tRenaming its variable to ›PRECT‹..."
			# And set variable name and description
			ncrename -v PRECL,PRECT "$PRECT_FILEPATH" 1>/dev/null
			# ncatted: -O: force overwrite existing file; 
			# 		   -a: attribute change description
			# 		   	  -> att_nm, var_nm, mode, att_type, att_val 
			# 		   	  -> mode = modify; att_type = character (string)
			echo -e "\tSetting its attribute ›long_name‹..."
			ncatted -O -a long_name,PRECT,m,c,"Total (convective and large-scale) precipitation rate (liq + ice)" "$PRECT_FILEPATH"
			
		else
			echo -e "\tError, file $PRECT_FILENAME not created."
		fi
		echo -e "\tRenaming variable in »$PRECC_FILENAME« back to PRECC..."
		ncrename -v PRECL,PRECC $PRECC_FILEPATH 1>/dev/null
		echo
	else
		echo "Missing file for PRECC that corresponds to the PRECL file »$PRECL_FILENAME«. Expected »$PRECC_FILENAME«"
	fi
done 

unset CROPPED_FILES_PRECC
unset CROPPED_FILES_PRECL


################################################################################
# CONCATENATE 
################################################################################
echo
echo "**************** CONCATENATE ******************"
for var in ${LPJ_VAR[@]}; do
	unset IN
	eval "IN=\${CROPPED_FILES_${var}[@]}" # input files

	eval "OUT=\${LPJ_FILE_$var}"
	
	if [[ -f "$OUT" ]]; then
		echo "Output file for variable $var already exists: »$OUT«"
		echo -e "\tTime range:$(print_time_range $OUT)"
		echo -e "\tDo you want to overwrite it? [y/n]"
		read -n  1 -r
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			echo -e "\t-> Skipped"
			continue
		fi
	fi
		
	if [[ "${#IN[@]}" > 0 ]]; then
		echo "Concatenating all cropped files for variable $var..."
		for f in ${IN[@]}; do
			echo -e "\t»$f«"
		done
		
		ncrcat -O --dimension time,0, ${IN[@]} "$OUT"
		if [[ -f "$OUT" ]]; then
			echo -e "\t-> File created: »$OUT«"
			echo -e "\t-> Time range: $(print_time_range $OUT)"
		else
			echo -e "\t->Error: No file created for variable $var."
		fi
	else
		echo "No cropped files found for variable $var."
	fi
done

################################################################################
# CROP TIME 
################################################################################
echo
echo "**************** CROP TIME ******************"
echo "Time range: $FIRSTYEAR – $LASTYEAR years BP"
for var in ${LPJ_VAR[@]}; do
	unset IN
	eval "IN=\${LPJ_FILE_${var}}" # input file

	echo "»$IN«"
	echo -e "\t->Original time range: $(print_time_range $IN)"
	echo -en "\t->Retrieving time dimension indices...  "
	# get the time indices (starting with 1) of the file
	S=$(Rscript ${SCRIPT_DIR}get_trace_time_indices.r $IN)
	if [[ "$S" != "" ]]; then
		TIME_START=${S% *} # first index: prefix in front of space
		TIME_STOP=${S##* } # last index: suffix after space
		echo "START:$TIME_START  STOP:$TIME_STOP"
		
		echo -e "\t->Cropping time hyperslab..."
		# hyperslab indexing starts with 0
		ncks -O -d time,${TIME_START},${TIME_STOP} "$IN" "$IN"
		echo -e "\t->New time range: $(print_time_range $IN)"
	else
		echo -e "\t->Error: Input file »$IN« does not cover specified time range. File left unchanged!"
	fi
done





################################################################################
# CHANGE ATTRIBUTES AND TIME TO CONFORM LPJ-GUESS
# Naming conventions for LPJ-GUESS CFInput module, taken from cfinput.cpp
# See also: note on calendar and time above in this script.
################################################################################
echo
echo "**************** CHANGE ATTRIBUTES AND RECALCULATE TIME ******************"
echo "New time unit and calendar (CF standard) are: »$CF_UNIT_TIME«; »$CF_CALENDAR«"
unset FIRST_LAT
for var in ${LPJ_VAR[@]}; do
	eval "FILENAME=\${LPJ_FILE_$var}"
	if [[ -f $FILENAME ]]; then
		echo "»${FILENAME}«"

		# Change unit and standard_name
		# ncatted: -O: force overwrite existing file; 
		# 		   -a: attribute change description
		# 		   	  -> att_nm, var_nm, mode, att_type, att_val 
		# 		   	  -> mode = overwrite (o); att_type = character (string)
		
		echo -e "\tChanging attributes to conform to CF standard..."
		eval "ncatted -O \
		-a standard_name,$var,o,c,\"\${CF_STANDARD_NAME_$var}\" \
		-a units,$var,o,c,\"\${CF_UNIT_$var}\" \
		-a units,time,o,c,\"${CF_UNIT_TIME}\" \
		-a calendar,time,o,c,\"${CF_CALENDAR}\" \
		-a units,lon,o,c,\"${CF_UNIT_LON}\"\
		-a standard_name,lon,o,c,\"${CF_STANDARD_NAME_LON}\" \
		-a units,lat,o,c,\"${CF_UNIT_LAT}\"\
		-a standard_name,lat,o,c,\"${CF_STANDARD_NAME_LAT}\" \
		\"${FILENAME}\""
		
		# Change variable name
		eval "LPJ_VAR=\${LPJ_VAR_$var}"
		if [ "$var" != "$LPJ_VAR" ]; then
			eval "echo -e \"\tChanging variable name from $var to \${LPJ_VAR_$var}...\""
			eval "ncrename -O -v \"$var\",\"\${LPJ_VAR_$var}\" \"${FILENAME}\""
		fi
		
		# Adjust the time dimension
		# 	--append: Overwrite existing time dimension
		echo -e "\tRecalculating time..."
		eval "ncap2 --append --script \"${TIME_SCRIPT}\" \"${FILENAME}\""
		
		
		## THIS CLEANING OF THE LATITUDE VALUES IS REALLY JUST A BAD, QUICK
		## AND DIRTY FIX!!
		## ACTUALLY THIS SCRIPT SHOULD RESAMPLE THE WHOLE FILE TO A GIVEN RESOLUTION...
		## BUT I DON’T WANT TO PUT EFFORT INTO IT AT THIS POINT.
		
		echo -e "\tCleaning trailing end of odd numbers from latitude:"
		# Find out the first latitude value and resolution
		if [ -z ${FIRST_LAT+x} ] ; then # if FIRST_LAT is still undefined
			eval "FIRST_LAT=\$(ncap2 --append --script-file \"${SCRIPT_DIR}get_trace_first_lat.nco\" \"${FILENAME}\")"
			echo -e "\tFirst latitude value for all files is $FIRST_LAT"
			
			eval "LAT_RES=\$(ncap2 --append --script-file \"${SCRIPT_DIR}get_trace_lat_res.nco\" \"${FILENAME}\")"
			echo -e "\tLatitude resolution for all files is $LAT_RES"
			
		fi
		echo -e "\tResetting latitude..."
		# write first latitude and resolution into other files to read them in the
		# ncap2 script
		eval "ncatted -O \
		-a resolution,lat,o,d,\"\${LAT_RES}\" \
		-a first,lat,o,d,\"\${FIRST_LAT}\" \
		\"${FILENAME}\""
		# Reset all latitude values
		eval "ncap2 --append --script-file \"${SCRIPT_DIR}trunc_trace_lat.nco\" \"${FILENAME}\""
		
	else
		echo "Expected file »$FILENAME« does not exist."
	fi
done



################################################################################
# CREATE CO2 FILE
# The R script requires the recalculated time
################################################################################
echo
echo "**************** CREATE CO₂ FILE ******************"
if [ -f "$CO2_REFERENCE_FILE" ]; then
	echo "Creating CO₂ file"
	echo "Starting R script »${SCRIPT_DIR}create_trace_co2.r«..."
	Rscript "${SCRIPT_DIR}create_trace_co2.r" 2>/dev/null
else
	echo "Reference file for CO₂ values does not exist: »$CO2_REFERENCE_FILE«"
fi
if [ -f "$LPJ_FILE_CO2" ]; then
	echo "CO₂ file created: »${LPJ_FILE_CO2}«"
else
	echo "Error: No CO₂ file created."
fi
echo


################################################################################
# CREATE GRIDCELL LIST 
# (see R file for details)
################################################################################
echo
echo "**************** CREATE GRIDCELL LIST ******************"
if [ -f "$GRIDLIST_REFERENCE_FILE" ]; then
	echo "Creating gridcell list"
	echo "Starting R script »${SCRIPT_DIR}create_ice5g_gridlist.r«..."
	Rscript "${SCRIPT_DIR}create_ice5g_gridlist.r" 2>/dev/null
else
	echo "Reference file for gridlist does not exist: »$GRIDLIST_REFERENCE_FILE«"
fi
if [ -f "${LPJ_FILE_GRIDLIST}" ]; then
	echo "Gridcell file created: »${LPJ_FILE_GRIDLIST}«"
else
	echo "Error: No gridcell file created."
fi
echo


################################################################################
# WRITE THE PARAMETERS FOR LPJ-GUESS INTO INSTRUCTION FILE
################################################################################
echo
echo "**************** WRITE INS FILE ******************"
echo "Writing LPJ-GUESS instruction file with file paths and variables to »${LPJ_FILE_INS}«..."

echo \
"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! INSTRUCTION FILE FOR LPJ-GUESS USING TRACE-21KA CLIMATE DRIVING DATA
! This file has been generated by the script ›prepare_trace_for_lpj.sh‹ 
! at $(date)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

param \"file_gridlist\" (str \"$LPJ_FILE_GRIDLIST\")

! Used to obtain soil codes
param \"file_cru\"     (str \"${LPJ_FILE_CRU}\")

param \"file_ndep\"     (str \"\") ! pre-industrial

param \"file_co2\"     (str \"${LPJ_FILE_CO2}\")

param \"file_temp\"     (str \"${LPJ_FILE_TREFHT}\")
param \"variable_temp\" (str \"${LPJ_VAR_TREFHT}\")

param \"file_insol\"      (str \"${LPJ_FILE_SOLIN}\")
param \"variable_insol\" (str \"${LPJ_VAR_SOLIN}\")

param \"file_prec\"     (str \"${LPJ_FILE_PRECT}\")
param \"variable_prec\" (str \"${LPJ_VAR_PRECT}\")

param \"file_wetdays\"     (str \"\")
param \"variable_wetdays\" (str \"wetdays\")

param \"file_min_temp\"      (str \"\")
param \"variable_min_temp\"  (str \"min_temp\")
param \"file_max_temp\"      (str \"\")
param \"variable_max_temp\"  (str \"max_temp\")
" > "${LPJ_FILE_INS}"
[ -f ${LPJ_FILE_INS} ] && echo "ins file created."

echo
echo "End."

