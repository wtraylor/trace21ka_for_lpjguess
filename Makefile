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

$(HEAP)/modern_monthly_avg_TREFHT.nc $(HEAP)/modern_monthly_avg_FSDS.nc $(HEAP)/modern_monthly_avg_PRECL.nc $(HEAP)/modern_monthly_avg_PRECC.nc : scripts/aggregate_modern_trace.py $(PYTHON) $(PYPKG)/xarray $(PYPKG)/yaml
	@$(PYTHON) scripts/aggregate_modern_trace.py

$(HEAP)/modern_monthly_avg_PRECT.nc : $(HEAP)/modern_monthly_avg_PRECL $(HEAP)/modern_monthly_avg_PRECC $(BIN)/ncbo $(BIN)/ncrename $(BIN)/ncatted
	@echo "Adding modern PRECC and PRECL to PRECT."
	ncbo --overwrite --op_typ='add' $(HEAP)/modern_monthly_avg_PRECL.nc $(HEAP)/modern_monthly_avg_PRECC.nc $(HEAP)/modern_monthly_avg_PRECT.nc
	@echo "Renaming the variable to 'PRECT'."
	ncrename --variable PRECL,PRECT $(HEAP)/modern_monthly_avg_PRECT.nc
	@echo "Updating the 'long_name' attribute."
	ncatted --overwrite --attribute long_name,PRECT,m,c,"Total (convective and large-scale) precipitation rate (liq + ice)" $(HEAP)/modern_monthly_avg_PRECT.nc
