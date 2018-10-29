# The directory for storing intermediary files.
# There should be some space there...
export HEAP ?= heap

###############################################################################

# The python executable
PYTHON = miniconda3/bin/python

miniconda3/bin/conda miniconda3/bin/pip $(PYTHON):
	@scripts/install_miniconda.sh

# Add all needed NCO binaries here as targets.
miniconda3/bin/ncatted miniconda3/bin/ncbo miniconda3/bin/ncremap miniconda3/bin/ncrename: miniconda3/bin/conda
	@scripts/install_nco.sh

# Add new python packages here as targets
miniconda3/lib/python3.7/site-packages/xarray/ miniconda3/lib/python3.7/site-packages/yaml/: miniconda3/bin/pip
	@scripts/install_python_packages.sh

$(HEAP)/modern_monthly_avg_TREFHT.nc $(HEAP)/modern_monthly_avg_FSDS.nc $(HEAP)/modern_monthly_avg_PRECL.nc $(HEAP)/modern_monthly_avg_PRECC.nc : scripts/aggregate_modern_trace.py $(PYTHON)
	@$(PYTHON) scripts/aggregate_modern_trace.py

$(HEAP)/modern_monthly_avg_PRECT.nc : $(HEAP)/modern_monthly_avg_PRECL $(HEAP)/modern_monthly_avg_PRECC miniconda3/bin/ncbo miniconda3/bin/ncrename miniconda3/bin/ncatted
	@echo "Adding modern PRECC and PRECL to PRECT."
	ncbo --overwrite --op_typ='add' $(HEAP)/modern_monthly_avg_PRECL.nc $(HEAP)/modern_monthly_avg_PRECC.nc $(HEAP)/modern_monthly_avg_PRECT.nc
	@echo "Renaming the variable to 'PRECT'."
	ncrename --variable PRECL,PRECT $(HEAP)/modern_monthly_avg_PRECT.nc
	@echo "Updating the 'long_name' attribute."
	ncatted --overwrite --attribute long_name,PRECT,m,c,"Total (convective and large-scale) precipitation rate (liq + ice)" $(HEAP)/modern_monthly_avg_PRECT.nc
