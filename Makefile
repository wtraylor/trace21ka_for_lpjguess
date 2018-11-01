# The directory for storing intermediary files.
# There should be some space there...
export HEAP ?= heap

###############################################################################
## VARIABLES
###############################################################################

# The root directory of the Miniconda installation.
MINICONDA = miniconda3

# The directory of binaries in the local Miniconda installation
BIN = $(MINICONDA)/bin/

# The python executable
PYTHON = $(BIN)/python

# Directory for Python packages.
PYPKG = $(MINICONDA)/lib/python3.7/site-packages/
# Individual Python packages. The '__init__.py' file is used as a proxy for
# whole package to check if it’s installed.
XARRAY = $(PYPKG)/xarray/__init__.py
YAML = $(PYPKG)/yaml/__init__.py

CDO = $(BIN)/cdo
NCO = $(BIN)/ncremap

###############################################################################
## INSTALLATION
###############################################################################

# We `touch` the installed files (the Make targets) so that they are marked as
# up-to-date even if the installation command doesn’t change them (because
# they are already installed.

# TODO: Use specific version and not latest version.
# TODO: Download 32 on 32-bit architectures.
CONDA_INSTALLER = Miniconda3-latest-Linux-x86_64.sh

$(CONDA_INSTALLER) :
	@echo
	@echo "Downloading Miniconda install script..."
	@wget "https://repo.continuum.io/miniconda/$(CONDA_INSTALLER)"
	@touch --no-create $(CONDA_INSTALLER)

# Miniconda installer command line arguments:
# -p PREFIX    install prefix, defaults to $PREFIX, must not contain spaces.
$(BIN)/conda $(BIN)/pip $(PYTHON): $(CONDA_INSTALLER)
	@echo
	@echo "Installing Miniconda to '$(MINICONDA)'..."
	@sh "$(CONDA_INSTALLER)" -p "$(MINICONDA)"
	@touch --no-create $(BIN)/conda $(BIN)/pip $(PYTHON)

# Add all needed NCO binaries here as targets.
$(NCO) : $(BIN)/conda
	@echo
	@echo "Installing NCO locally with Miniconda..."
	@$(BIN)/conda install -c conda-forge nco
	@touch --no-create $(NCO)

$(CDO) : $(BIN)/conda
	@echo
	@echo "Installing CDO locally with Miniconda..."
	@$(BIN)/conda install -c conda-forge cdo
	@touch --no-create $(CDO)

# Add new python packages here as targets and as arguments to `pip`.
$(XARRAY) $(YAML): $(BIN)/pip
	@echo
	@echo "Installing Python packages with PIP..."
	@$(BIN)/pip install xarray pyyaml
	@touch --no-create $(XARRAY) $(YAML)

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
	@echo
	@$(PYTHON) scripts/aggregate_modern_trace.py TREFHT

$(HEAP)/modern_trace_FSDS.nc : trace_orig/ scripts/aggregate_modern_trace.py $(PYTHON) $(XARRAY) $(YAML) options.yaml
	@echo
	@$(PYTHON) scripts/aggregate_modern_trace.py FSDS

$(HEAP)/modern_trace_PRECL.nc : trace_orig/ scripts/aggregate_modern_trace.py $(PYTHON) $(XARRAY) $(YAML) options.yaml
	@echo
	@$(PYTHON) scripts/aggregate_modern_trace.py PRECL

$(HEAP)/modern_trace_PRECC.nc : trace_orig/ scripts/aggregate_modern_trace.py $(PYTHON) $(XARRAY) $(YAML) options.yaml
	@echo
	@$(PYTHON) scripts/aggregate_modern_trace.py PRECC

$(HEAP)/modern_trace_PRECT.nc : $(HEAP)/modern_trace_PRECL.nc $(HEAP)/modern_trace_PRECC.nc $(NCO)
	@echo
	@env PATH="$(BIN):$(PATH)" \
		scripts/add_modern_monthly_PRECC_PRECL.sh

###############################################################################
## REGRID MODERN TRACE DATA
###############################################################################

# Template NetCDF file for regridding (=downscaling).
GRID_TEMPL = cruncep/temperature.nc

# ERWG interpolation algorithm for downscaling.
REGRID_ALG = bilinear

$(HEAP)/modern_trace_FSDS_regrid.nc : $(GRID_TEMPL) $(HEAP)/modern_trace_FSDS.nc $(NCO)
	@echo
	@echo "Downscaling modern FSDS file..."
	@env PATH="$(BIN):$(PATH)" \
		ncremap \
		--algorithm="$(REGRID_ALG)" \
		--template_file="$(GRID_TEMPL)" \
		--input_file="$(HEAP)/modern_trace_FSDS.nc" \
		--output_file="$(HEAP)/modern_trace_FSDS_regrid.nc"

$(HEAP)/modern_trace_PRECT_regrid.nc : $(GRID_TEMPL) $(HEAP)/modern_trace_PRECT.nc $(NCO)
	@echo
	@echo "Downscaling modern PRECT file..."
	@env PATH="$(BIN):$(PATH)" \
		ncremap \
		--algorithm="$(REGRID_ALG)" \
		--template_file="$(GRID_TEMPL)" \
		--input_file="$(HEAP)/modern_trace_PRECT.nc" \
		--output_file="$(HEAP)/modern_trace_PRECT_regrid.nc"

$(HEAP)/modern_trace_TREFHT_regrid.nc : $(GRID_TEMPL) $(HEAP)/modern_trace_TREFHT.nc $(NCO)
	@echo
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
	@echo
	@echo "Calculating bias for variable 'PRECT'..."
	@$(PYTHON) scripts/calculate_bias.py "PRECT"

$(HEAP)/bias_TREFHT.nc : $(HEAP)/modern_trace_TREFHT_regrid $(XARRAY) $(PYTHON) $(YAML) options.yaml
	@echo
	@echo "Calculating bias for variable 'TREFHT'..."
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
$(HEAP)/cropped/%.nc : trace_orig/%.nc scripts/crop_file.py $(NCO) $(PYTHON) $(YAML)
	@echo
	@echo "Cropping file '$<'..."
	@mkdir --parents $(HEAP)/cropped
	@$(PYTHON) scripts/crop_file.py $< $@

###############################################################################
## SPLIT INTO 100 YEARS FILES
###############################################################################

# Create 100 years files (1200 time steps, 12*100 months) for each cropped file.
# The split files are saved in a folder of the original file name (without .nc
# suffix), labeled 000000.nc, 000001.nc, 000002.nc, etc.
$(HEAP)/split/% : $(HEAP)/cropped/%.nc $(HEAP)/split $(CDO)
	@echo
	@echo "Splitting file '$@' into 100-years slices."
	@mkdir --parents $@
	@env PATH="$(BIN):$(PATH)" \
		cdo splitsel,1200 $< $@/
