# The directory for storing intermediary files.
# There should be some space there...
export HEAP ?= heap

###############################################################################

# The python executable
PYTHON = miniconda3/bin/python

miniconda3/bin/conda miniconda3/bin/pip $(PYTHON):
	@scripts/install_miniconda.sh

miniconda3/bin/ncremap : miniconda3/bin/conda
	@scripts/install_nco.sh

# Add new python packages here as targets
miniconda3/lib/python3.7/site-packages/xarray : miniconda3/bin/pip
	@scripts/install_python_packages.sh

$(HEAP)/modern_monthly_avg_TREFHT.nc $(HEAP)/modern_monthly_avg_FSDS.nc $(HEAP)/modern_monthly_avg_PRECL.nc $(HEAP)/modern_monthly_avg_PRECC.nc : scripts/aggregate_modern_trace.py $(PYTHON)
	@$(PYTHON) scripts/aggregate_modern_trace.py

