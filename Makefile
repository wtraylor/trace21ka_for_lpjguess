# The directory for storing intermediary files.
# There should be some space there...
export HEAP ?= heap

###############################################################################
## ORIGINAL TRACE FILES
###############################################################################

PRECC := trace.*PRECC*.nc
PRECL := trace.*PRECL*.nc
TREFHT := trace.*TREFHT*.nc

# All original TraCE files. TODO: Add rest of the files.
ALL_ORIG = $(wildcard trace_orig/$(PRECC)) $(wildcard trace_orig/$(PRECL)) $(wildcard trace_orig/$(TREFHT))

###############################################################################
## PHONY TARGETS
###############################################################################

.PHONY: all
# TODO: This is only a stub so far.
all :
	@echo "Not implemented yet."

# For every original TraCE file there is one cropped file.
CROPPED_FILES = $(patsubst trace_orig/%, $(HEAP)/cropped/%, $(ALL_ORIG))

# For every cropped file there is one (first!) split file with index 000000.
# This file represents the rest (varying amount!) of the time slices.
SPLIT_FILES = $(patsubst trace_orig/%.nc, $(HEAP)/split/%000000.nc, $(ALL_ORIG))

# For every split file there is one downscaled file.
# The amount of downscaled files can only be determined after splitting is done!
DOWNSCALED_FILES = $(patsubst $(HEAP)/split/%, $(HEAP)/downscaled/%, $(wildcard $(HEAP)/split/*.nc))

.PHONY: downscale
# Splitting creates files (*000000.nc, *000001.nc,...) that are not known
# before actually executing the splitting. Therefore, the `SPLIT_FILES` are
# first dependency. After they are created, the wildcard in `DOWNSCALED_FILES`
# variable is parsed correctly.
downscale : $(SPLIT_FILES) $(DOWNSCALED_FILES)
	@echo "Downscaling finished."

.PHONY: split
split : $(SPLIT_FILES)
	@echo "Splitting finished."

.PHONY: crop
# This target depends on all original TraCE files being cropped in the folder
# '$(HEAP)/cropped/'.
crop : $(CROPPED_FILES)
	@echo "Cropping finished."

.PHONY: clean
# Be cautious: Only remove those files and directories that are also created
# by this script.
# Append `exit 0` to the `rm` command so that the return code is always
# SUCCESS. Otherwise the rule fails if `rm` doesn’t find a file/directory.
# Also remove the symbolic link "trace_orig".
clean :
	@rm --verbose \
		heap/bias_*.nc \
		heap/cropped/trace*.nc \
		heap/downscaled/**trace*.nc \
		heap/modern_trace_*.nc \
		heap/split/**.nc \
		2>/dev/null; \
		exit 0
	@rm --dir --verbose \
		heap/cropped \
		heap/downscaled/trace* \
		heap/downscaled \
		heap/split/trace* \
		heap/split \
		2>/dev/null; \
		exit 0
	@rm --verbose \
		trace_orig \
		2>/dev/null; \
		exit 0

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
NETCDF4 = $(PYPKG)/netCDF4/__init__.py
SCIPY = $(PYPKG)/scipy/__init__.py
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

$(NETCDF4) : $(BIN)/pip
	@echo
	@$(BIN)/pip install netCDF4
	@touch --no-create $(NETCDF4)

$(SCIPY) : $(BIN)/pip
	@echo
	@$(BIN)/pip install scipy
	@touch --no-create $(SCIPY)

$(YAML) : $(BIN)/pip
	@echo
	@$(BIN)/pip install pyyaml
	@touch --no-create $(YAML)

$(XARRAY) : $(BIN)/pip
	@echo
	@$(BIN)/pip install xarray
	@touch --no-create $(XARRAY)

###############################################################################
## SYMLINK ORIGINAL TRACE FILES
###############################################################################

trace_orig : scripts/symlink_trace_orig.py $(PYTHON) $(YAML) options.yaml
	@$(PYTHON) scripts/symlink_trace_orig.py

###############################################################################
## AGGREGATE MODERN TRACE DATA
###############################################################################

$(HEAP)/modern_trace_TREFHT.nc : trace_orig/ scripts/aggregate_modern_trace.py $(PYTHON) $(NETCDF4) $(SCIPY) $(XARRAY) $(YAML) options.yaml
	@echo
	@$(PYTHON) scripts/aggregate_modern_trace.py TREFHT

$(HEAP)/modern_trace_FSDS.nc : trace_orig/ scripts/aggregate_modern_trace.py $(PYTHON) $(NETCDF4) $(SCIPY) $(XARRAY) $(YAML) options.yaml
	@echo
	@$(PYTHON) scripts/aggregate_modern_trace.py FSDS

$(HEAP)/modern_trace_PRECL.nc : trace_orig/ scripts/aggregate_modern_trace.py $(PYTHON) $(NETCDF4) $(SCIPY) $(XARRAY) $(YAML) options.yaml
	@echo
	@$(PYTHON) scripts/aggregate_modern_trace.py PRECL

$(HEAP)/modern_trace_PRECC.nc : trace_orig/ scripts/aggregate_modern_trace.py $(PYTHON) $(NETCDF4) $(SCIPY) $(XARRAY) $(YAML) options.yaml
	@echo
	@$(PYTHON) scripts/aggregate_modern_trace.py PRECC

$(HEAP)/modern_trace_PRECT.nc : $(HEAP)/modern_trace_PRECL.nc $(HEAP)/modern_trace_PRECC.nc $(NCO) scripts/add_PRECC_PRECL.sh
	@echo
	@env PATH="$(BIN):$(PATH)" \
		scripts/add_PRECC_PRECL.sh \
		$(HEAP)/modern_trace_PRECC.nc \
		$(HEAP)/modern_trace_PRECL.nc \
		$(HEAP)/modern_trace_PRECT.nc

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

$(HEAP)/bias_PRECT.nc : $(HEAP)/modern_trace_PRECT_regrid.nc scripts/calculate_bias.py $(XARRAY) $(PYTHON) $(YAML) options.yaml
	@echo
	@echo "Calculating bias for variable 'PRECT'..."
	@$(PYTHON) scripts/calculate_bias.py "PRECT"

$(HEAP)/bias_TREFHT.nc : $(HEAP)/modern_trace_TREFHT_regrid.nc scripts/calculate_bias.py $(XARRAY) $(PYTHON) $(YAML) options.yaml
	@echo
	@echo "Calculating bias for variable 'TREFHT'..."
	@$(PYTHON) scripts/calculate_bias.py "TREFHT"

###############################################################################
## CROPPING
###############################################################################

# For each original TraCE file there is a rule to create the corresponding
# cropped NetCDF file (with the same name) in $(HEAP)/cropped.
$(HEAP)/cropped/%.nc : trace_orig/%.nc scripts/crop_file.py $(NCO) $(PYTHON) $(YAML) options.yaml
	@echo
	@mkdir --parents $(HEAP)/cropped
	@$(PYTHON) scripts/crop_file.py $< $@

###############################################################################
## SPLIT INTO 100 YEARS FILES
###############################################################################

# Create 100 years files (1200 time steps, 12*100 months) for each cropped file.
# The split files are named with a suffix to the original file name:
# *000000.nc,: *000001.nc,: *000002.nc, etc.
# The original TraCE files are of varying time length, so the number of created
# split files is not known beforehand. Therefore, we use the first split file
# (index 000000) as a representative target for all split files.
$(HEAP)/split/%000000.nc : $(HEAP)/cropped/%.nc $(CDO)
	@echo
	@echo "Splitting file '$<' into 100-years slices."
	@env PATH="$(BIN):$(PATH)" \
		cdo splitsel,1200 $< $(patsubst %.nc, %, $@)

###############################################################################
## DOWNSCALE TRACE FILES
###############################################################################

# For every split file, there is a downscaled target.
$(HEAP)/downscaled/%.nc : $(HEAP)/split/%.nc $(NCO)
	@echo
	@mkdir --parents $(HEAP)/downscaled
	@echo "Regridding '$@'..."
	@env PATH="$(BIN):$(PATH)" \
		ncremap \
		--algorithm="$(REGRID_ALG)" \
		--template_file="$(GRID_TEMPL)" \
		--input_file="$@" \
		--output_file="$<"
