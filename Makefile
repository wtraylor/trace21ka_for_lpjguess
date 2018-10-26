# The directory for storing intermediary files.
# There should be some space there...
HEAP ?= "heap"

###############################################################################

	@scripts/install_miniconda.sh

miniconda3/bin/ncremap : miniconda3/bin/conda
	@scripts/install_nco.sh

# Add new python packages here as targets
miniconda3/lib/python3.7/site-packages/xarray : miniconda3/bin/pip
	@scripts/install_python_packages.sh

# TODO: add rule for scripts/downscale_trace_file.sh
