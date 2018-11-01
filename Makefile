# The directory for storing intermediary files.
# There should be some space there...
export HEAP ?= heap

###############################################################################
## VARIABLES
###############################################################################

# The directory of binaries in the local Miniconda installation
BIN = miniconda3/bin/

# The python executable
PYTHON = $(BIN)/python

# Directory for Python packages.
PYPKG = miniconda3/lib/python3.7/site-packages/
# Individual Python packages.
XARRAY = $(PYPKG)/xarray
YAML = $(PYPKG)/yaml

###############################################################################
## INSTALLATION
###############################################################################

$(BIN)/conda $(BIN)/pip $(PYTHON):
	@scripts/install_miniconda.sh

# Add all needed NCO binaries here as targets.
$(BIN)/ncatted $(BIN)/ncbo $(BIN)/ncks $(BIN)/ncremap $(BIN)/ncrename : $(BIN)/conda
	@scripts/install_nco.sh

$(BIN)/cdo : $(BIN)/conda
	@echo
	@echo "Installing CDO locally with Miniconda..."
	@$(BIN)/conda install -c conda-forge cdo

# Add new python packages here as targets.
$(XARRAY) $(YAML): $(BIN)/pip
	@scripts/install_python_packages.sh

###############################################################################
## SYMLINK ORIGINAL TRACE FILES
###############################################################################

trace_orig : $(PYTHON) $(YAML) options.yaml
	@$(PYTHON) scripts/symlink_trace_orig.py

TREFHT = trace.01.22000-20001BP.cam2.h0.TREFHT.0000101-0200012.nc \
				 trace.02.20000-19001BP.cam2.h0.TREFHT.0200101-0300012.nc

# All original TraCE files. TODO: Add rest of the files.
ALL_ORIG = $(TREFHT)

###############################################################################
## AGGREGATE MODERN TRACE DATA
###############################################################################

$(HEAP)/modern_trace_TREFHT.nc : trace_orig/ scripts/aggregate_modern_trace.py $(PYTHON) $(XARRAY) $(YAML) options.yaml
	@$(PYTHON) scripts/aggregate_modern_trace.py TREFHT

$(HEAP)/modern_trace_FSDS.nc : trace_orig/ scripts/aggregate_modern_trace.py $(PYTHON) $(XARRAY) $(YAML) options.yaml
	@$(PYTHON) scripts/aggregate_modern_trace.py FSDS

$(HEAP)/modern_trace_PRECL.nc : trace_orig/ scripts/aggregate_modern_trace.py $(PYTHON) $(XARRAY) $(YAML) options.yaml
	@$(PYTHON) scripts/aggregate_modern_trace.py PRECL

$(HEAP)/modern_trace_PRECC.nc : trace_orig/ scripts/aggregate_modern_trace.py $(PYTHON) $(XARRAY) $(YAML) options.yaml
	@$(PYTHON) scripts/aggregate_modern_trace.py PRECC

$(HEAP)/modern_trace_PRECT.nc : $(HEAP)/modern_trace_PRECL.nc $(HEAP)/modern_trace_PRECC.nc $(BIN)/ncbo $(BIN)/ncrename $(BIN)/ncatted
	@env PATH="$(BIN):$(PATH)" \
		scripts/add_modern_monthly_PRECC_PRECL.sh

###############################################################################
## REGRID MODERN TRACE DATA
###############################################################################

# Template NetCDF file for regridding (=downscaling).
GRID_TEMPL = cruncep/temperature.nc

# ERWG interpolation algorithm for downscaling.
REGRID_ALG = bilinear

$(HEAP)/modern_trace_FSDS_regrid.nc : $(GRID_TEMPL) $(HEAP)/modern_trace_FSDS.nc $(BIN)/ncremap
	@echo "Downscaling modern FSDS file..."
	@env PATH="$(BIN):$(PATH)" \
		ncremap \
		--algorithm="$(REGRID_ALG)" \
		--template_file="$(GRID_TEMPL)" \
		--input_file="$(HEAP)/modern_trace_FSDS.nc" \
		--output_file="$(HEAP)/modern_trace_FSDS_regrid.nc"

$(HEAP)/modern_trace_PRECT_regrid.nc : $(GRID_TEMPL) $(HEAP)/modern_trace_PRECT.nc $(BIN)/ncremap
	@echo "Downscaling modern PRECT file..."
	@env PATH="$(BIN):$(PATH)" \
		ncremap \
		--algorithm="$(REGRID_ALG)" \
		--template_file="$(GRID_TEMPL)" \
		--input_file="$(HEAP)/modern_trace_PRECT.nc" \
		--output_file="$(HEAP)/modern_trace_PRECT_regrid.nc"

$(HEAP)/modern_trace_TREFHT_regrid.nc : $(GRID_TEMPL) $(HEAP)/modern_trace_TREFHT.nc $(BIN)/ncremap
	@echo "Downscaling modern TREFHT file..."
	@env PATH="$(BIN):$(PATH)" \
		ncremap \
		--algorithm="$(REGRID_ALG)" \
		--template_file="$(GRID_TEMPL)" \
		--input_file="$(HEAP)/modern_trace_TREFHT.nc" \
		--output_file="$(HEAP)/modern_trace_TREFHT_regrid.nc"

###############################################################################
## CALCULATE BIAS
###############################################################################

$(HEAP)/bias_PRECT.nc : $(HEAP)/modern_trace_PRECT_regrid $(XARRAY) $(PYTHON) $(YAML) options.yaml
	@echo "Calculating bias for variable 'PRECT'."
	@$(PYTHON) scripts/calculate_bias.py "PRECT"

$(HEAP)/bias_TREFHT.nc : $(HEAP)/modern_trace_TREFHT_regrid $(XARRAY) $(PYTHON) $(YAML) options.yaml
	@echo "Calculating bias for variable 'TREFHT'."
	@$(PYTHON) scripts/calculate_bias.py "TREFHT"

###############################################################################
## CROPPING
###############################################################################

# This target depends on all original TraCE files being cropped in the folder
# '$(HEAP)/cropped/'.
.PHONY: crop
crop : $(patsubst %, $(HEAP)/cropped/%, $(ALL_ORIG))
	@echo "Cropping finished."

# For each original TraCE file there is a rule to create the corresponding
# cropped NetCDF file (with the same name) in $(HEAP)/cropped.
$(HEAP)/cropped/%.nc : trace_orig/%.nc scripts/crop_file.py $(BIN)/ncks
	@mkdir --parents $(HEAP)/cropped
	@$(PYTHON) scripts/crop_file.py $< $@

###############################################################################
## SPLIT INTO 100 YEARS FILES
###############################################################################

# Create 100 years files (1200 time steps, 12*100 months) for each cropped file.
# The split files are saved in a folder of the original file name (without .nc
# suffix), labeled 000000.nc, 000001.nc, 000002.nc, etc.
$(HEAP)/split/% : $(HEAP)/cropped/%.nc $(HEAP)/split $(BIN)/cdo
	@mkdir --parents $@
	@env PATH="$(BIN):$(PATH)" \
		cdo splitsel,1200 $< $@/
