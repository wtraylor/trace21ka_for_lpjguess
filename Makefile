# The directory for storing intermediary files.
# There should be some space there...
export HEAP ?= heap

###############################################################################

# The directory of binaries in the local Miniconda installation
BIN = miniconda3/bin/

# The python executable
PYTHON = $(BIN)/python

$(BIN)/conda $(BIN)/pip $(PYTHON):
	@scripts/install_miniconda.sh

# Add all needed NCO binaries here as targets.
$(BIN)/ncatted $(BIN)/ncbo $(BIN)/ncremap $(BIN)/ncrename: $(BIN)/conda
	@scripts/install_nco.sh

# Directory for Python packages.
PYPKG = miniconda3/lib/python3.7/site-packages/

# Add new python packages here as targets.
$(PYPKG)/xarray/ $(PYPKG)/yaml/: $(BIN)/pip
	@scripts/install_python_packages.sh

$(HEAP)/modern_trace_TREFHT.nc $(HEAP)/modern_trace_FSDS.nc $(HEAP)/modern_trace_PRECL.nc $(HEAP)/modern_trace_PRECC.nc : scripts/aggregate_modern_trace.py $(PYTHON) $(PYPKG)/xarray $(PYPKG)/yaml
	@$(PYTHON) scripts/aggregate_modern_trace.py

$(HEAP)/modern_trace_PRECT.nc : $(HEAP)/modern_trace_PRECL $(HEAP)/modern_trace_PRECC $(BIN)/ncbo $(BIN)/ncrename $(BIN)/ncatted
	@env PATH="$(BIN):$(PATH)" \
		scripts/add_modern_monthly_PRECC_PRECL.sh

# Template NetCDF file for regridding (=downscaling).
GRID_TEMPL = cruncep/temperature.nc

# ERWG interpolation algorithm for downscaling.
REGRID_ALG = bilinear

$(HEAP)/modern_trace_FSDS_regrid.nc $(GRID_TEMPL) : $(HEAP)/modern_trace_FSDS.nc $(BIN)/ncremap
	@echo "Downscaling modern FSDS file..."
	@env PATH="$(BIN):$(PATH)" \
		ncremap \
		--algorithm="$(REGRID_ALG)" \
		--template_file="$(GRID_TEMPL)" \
		--input_file="$(HEAP)/modern_trace_FSDS.nc" \
		--output_file="$(HEAP)/modern_trace_FSDS_regrid.nc"

$(HEAP)/modern_trace_PRECT_regrid.nc $(GRID_TEMPL) : $(HEAP)/modern_trace_PRECT.nc $(BIN)/ncremap
	@echo "Downscaling modern PRECT file..."
	@env PATH="$(BIN):$(PATH)" \
		ncremap \
		--algorithm="$(REGRID_ALG)" \
		--template_file="$(GRID_TEMPL)" \
		--input_file="$(HEAP)/modern_trace_PRECT.nc" \
		--output_file="$(HEAP)/modern_trace_PRECT_regrid.nc"

$(HEAP)/modern_trace_TREFHT_regrid.nc $(GRID_TEMPL) : $(HEAP)/modern_trace_TREFHT.nc $(BIN)/ncremap
	@echo "Downscaling modern TREFHT file..."
	@env PATH="$(BIN):$(PATH)" \
		ncremap \
		--algorithm="$(REGRID_ALG)" \
		--template_file="$(GRID_TEMPL)" \
		--input_file="$(HEAP)/modern_trace_TREFHT.nc" \
		--output_file="$(HEAP)/modern_trace_TREFHT_regrid.nc"
