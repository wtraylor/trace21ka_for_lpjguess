# These path variables may be overridden by the user:

TRACE_ORIG ?= "trace_original"

miniconda3/bin/conda :
	@scripts/install_miniconda.sh

miniconda3/bin/ncremap : miniconda3/bin/conda
	@scripts/install_nco.sh
