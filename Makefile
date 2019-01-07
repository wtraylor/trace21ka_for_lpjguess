###############################################################################
## ORIGINAL TRACE FILES
###############################################################################

PRECC := trace.*PRECC*.nc
PRECL := trace.*PRECL*.nc
TREFHT := trace.*TREFHT*.nc

# All original TraCE files. TODO: Add rest of the files.
ALL_ORIG = $(wildcard trace_orig/$(PRECC)) $(wildcard trace_orig/$(PRECL)) $(wildcard trace_orig/$(TREFHT))

###############################################################################
## TARGET FILES
###############################################################################

# For every original TraCE file there is one cropped file.
# We need to calculate PRECT files from PRECC and PRECL. For that, we first
# create a list of cropped files with PRECC and PRECL (and without PRECT),
# directly from what we have as input. Afterwards, we substitute all 'PRECC'
# and 'PRECL' with 'PRECT' in the list and remove duplicates. So any PRECC and
# PRECL files are removed, but corresponding PRECT files are added. Now we have
# all a list of all cropped files that are actually needed for further
# processing.
CROPPED_FILES_ORIG = $(patsubst trace_orig/%, heap/cropped/%, $(ALL_ORIG))
CROPPED_FILES = $(shell echo $(CROPPED_FILES_ORIG) | \
								sed 's/ /\n/g' | \
								sed 's/PREC[CL]/PRECT/g' | \
								sort | \
								uniq)

# For every cropped file there is one (first!) split file with index 000000.
# This file represents the rest (varying amount!) of the time slices.
# Of all the cropped files we filter out all PRECC and PRECL files because they
# are already combined to PRECT.
ALL_SPLIT_FILES = $(patsubst heap/cropped/%.nc, heap/split/%000000.nc, $(CROPPED_FILES))
SPLIT_FILES = $(shell echo $(ALL_SPLIT_FILES) | \
							sed 's/ /\n/g' | \
							sed '/PREC[CL]/d')

# For every split file there is one downscaled file.
# The amount of downscaled files can only be determined after splitting is done!
DOWNSCALED_FILES = $(patsubst heap/split/%, heap/downscaled/%, $(wildcard heap/split/*.nc))

DEBIASED_TREFHT = $(shell echo $(DOWNSCALED_FILES) | \
									sed 's/downscaled/debiased/g' | \
									sed 's/ /\n/g' | \
									grep 'TREFHT')
DEBIASED_PRECT = $(shell echo $(DOWNSCALED_FILES) | \
								 sed 's/downscaled/debiased/g' | \
								 sed 's/ /\n/g' | \
								 grep 'PRECT')

OUTPUT_FILES = $(patsubst heap/debiased/%, output/%, $(DEBIASED_TREFHT) $(DEBIASED_PRECT))

###############################################################################
## VARIABLES
###############################################################################

# TODO: Use specific version and not latest version.
# TODO: Download 32 on 32-bit architectures.
CONDA_INSTALLER = Miniconda3-latest-Linux-x86_64.sh

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
TERMCOLOR = $(PYPKG)/termcolor.py
XARRAY = $(PYPKG)/xarray/__init__.py
YAML = $(PYPKG)/yaml/__init__.py

CDO = $(BIN)/cdo
NCO = $(BIN)/ncremap

###############################################################################
## PHONY TARGETS
###############################################################################

# Splitting creates files (*000000.nc, *000001.nc,...) that are not known
# before actually executing the splitting. Therefore, the `SPLIT_FILES` are
# first dependency for any rules after splitting. After the split files are
# created, the wildcards in the variables `DOWNSCALED_FILES`,
# `DEBIASED_TREFHT`, etc. are parsed correctly.

###############################################################################
## INSTALLATION
###############################################################################

# We `touch` the installed files (the Make targets) so that they are marked as
# up-to-date even if the installation command doesn’t change them (because
# they are already installed.

# For some reasen, the download with `wget` did not always work reliably. With
# `curl` it is no problem.

$(CONDA_INSTALLER) :
	@echo "Downloading Miniconda install script..."
	@curl "https://repo.continuum.io/miniconda/$(CONDA_INSTALLER)" > \
		$(CONDA_INSTALLER)
	@touch --no-create $(CONDA_INSTALLER)

# Miniconda installer command line arguments:
# -p PREFIX    install prefix, defaults to $PREFIX, must not contain spaces.
# -u           update an existing installation
$(BIN)/conda $(BIN)/pip $(PYTHON): $(CONDA_INSTALLER)
	@echo "Installing Miniconda to '$(MINICONDA)'..."
	@sh "$(CONDA_INSTALLER)" -u -p "$(MINICONDA)"
	@touch --no-create $(BIN)/conda $(BIN)/pip $(PYTHON)

# Add all needed NCO binaries here as targets.
$(NCO) : $(BIN)/conda
	@echo "Installing NCO locally with Miniconda..."
	@$(BIN)/conda install --yes --channel conda-forge nco
	@touch --no-create $(NCO)

$(CDO) : $(BIN)/conda
	@echo "Installing CDO locally with Miniconda..."
	@$(BIN)/conda install --yes --channel conda-forge cdo
	@touch --no-create $(CDO)

$(NETCDF4) : $(BIN)/pip
	@$(BIN)/pip install netCDF4
	@touch --no-create $(NETCDF4)

$(SCIPY) : $(BIN)/pip
	@$(BIN)/pip install scipy
	@touch --no-create $(SCIPY)

$(TERMCOLOR) : $(BIN)/pip
	@$(BIN)/pip install termcolor
	@touch --no-create $(TERMCOLOR)

$(YAML) : $(BIN)/pip
	@$(BIN)/pip install pyyaml
	@touch --no-create $(YAML)

$(XARRAY) : $(BIN)/pip $(NETCDF4) $(SCIPY)
	@$(BIN)/pip install xarray
	@touch --no-create $(XARRAY)

###############################################################################
## PREREQUISITES FOR EACH SCRIPT
###############################################################################

scripts/add_PRECC_PRECL.sh : $(NCO)

scripts/aggregate_crujra.sh : $(CDO)

scripts/aggregate_modern_trace.py : $(PYTHON) $(TERMCOLOR) $(XARRAY)

scripts/calculate_bias.py : $(PYTHON) $(TERMCOLOR) $(XARRAY) $(YAML) options.yaml

scripts/crop_file.py : $(PYTHON) $(TERMCOLOR) $(YAML) $(NCO) options.yaml

scripts/debias.py : $(PYTHON) $(TERMCOLOR) $(XARRAY) heap/crujra/monthly_std_regrid.nc

scripts/rescale.py : $(PYTHON) $(TERMCOLOR) $(YAML) $(NCO) options.yaml heap/grid_template.nc

scripts/symlink_dir.py : $(PYTHON) $(TERMCOLOR) $(YAML) options.yaml

###############################################################################
## SPLIT INTO 100 YEARS FILES
###############################################################################

# Create 100 years files (1200 time steps, 12*100 months) for each cropped file.
# The split files are named with a suffix to the original file name:
# *000000.nc,: *000001.nc,: *000002.nc, etc.
# The original TraCE files are of varying time length, so the number of created
# split files is not known beforehand. Therefore, we use the first split file
# (index 000000) as a representative target for all split files.
heap/split/%000000.nc : heap/cropped/%.nc $(CDO)
	@mkdir --parents heap/split
	@echo "Splitting file '$<' into 100-years slices."
	@env PATH="$(BIN):$(PATH)" \
		cdo splitsel,1200 $< $(patsubst %.nc, %, $@)

###############################################################################
## CALCULATING PRECC + PRECL = PRECT
###############################################################################

# Here are all rules for creating the PRECT files.
# Unfortunately, Make does not offer an easy solution to generate these rules
# automatically.

# This "canned rule" applies to all the PRECT files. The first prerequisite is
# the PRECC file, the second is the PRECL file.
# This way we save some repetition when defining rules for all PRECT files.
define PRECT_RULE =
@env PATH="$(BIN):$(PATH)" \
	scripts/add_PRECC_PRECL.sh \
	$(word 1,$^) \
	$(word 2,$^) \
	$@
endef

heap/cropped/trace.01.22000-20001BP.cam2.h0.PRECT.0000101-0200012.nc : \
	heap/cropped/trace.01.22000-20001BP.cam2.h0.PRECC.0000101-0200012.nc \
	heap/cropped/trace.01.22000-20001BP.cam2.h0.PRECL.0000101-0200012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.02.20000-19001BP.cam2.h0.PRECT.0200101-0300012.nc : \
	heap/cropped/trace.02.20000-19001BP.cam2.h0.PRECC.0200101-0300012.nc \
	heap/cropped/trace.02.20000-19001BP.cam2.h0.PRECL.0200101-0300012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.03.19000-18501BP.cam2.h0.PRECT.0300101-0350012.nc : \
	heap/cropped/trace.03.19000-18501BP.cam2.h0.PRECC.0300101-0350012.nc \
	heap/cropped/trace.03.19000-18501BP.cam2.h0.PRECL.0300101-0350012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.04.18500-18401BP.cam2.h0.PRECT.0350101-0360012.nc : \
	heap/cropped/trace.04.18500-18401BP.cam2.h0.PRECC.0350101-0360012.nc \
	heap/cropped/trace.04.18500-18401BP.cam2.h0.PRECL.0350101-0360012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.05.18400-17501BP.cam2.h0.PRECT.0360101-0450012.nc : \
	heap/cropped/trace.05.18400-17501BP.cam2.h0.PRECC.0360101-0450012.nc \
	heap/cropped/trace.05.18400-17501BP.cam2.h0.PRECL.0360101-0450012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.06.17500-17001BP.cam2.h0.PRECT.0450101-0500012.nc : \
	heap/cropped/trace.06.17500-17001BP.cam2.h0.PRECC.0450101-0500012.nc \
	heap/cropped/trace.06.17500-17001BP.cam2.h0.PRECL.0450101-0500012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.07.17000-16001BP.cam2.h0.PRECT.0500101-0600012.nc : \
	heap/cropped/trace.07.17000-16001BP.cam2.h0.PRECC.0500101-0600012.nc \
	heap/cropped/trace.07.17000-16001BP.cam2.h0.PRECL.0500101-0600012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.08.16000-15001BP.cam2.h0.PRECT.0600101-0700012.nc : \
	heap/cropped/trace.08.16000-15001BP.cam2.h0.PRECC.0600101-0700012.nc \
	heap/cropped/trace.08.16000-15001BP.cam2.h0.PRECL.0600101-0700012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.09.15000-14901BP.cam2.h0.PRECT.0700101-0710012.nc : \
	heap/cropped/trace.09.15000-14901BP.cam2.h0.PRECC.0700101-0710012.nc \
	heap/cropped/trace.09.15000-14901BP.cam2.h0.PRECL.0700101-0710012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.10.14900-14351BP.cam2.h0.PRECT.0710101-0765012.nc : \
	heap/cropped/trace.10.14900-14351BP.cam2.h0.PRECC.0710101-0765012.nc \
	heap/cropped/trace.10.14900-14351BP.cam2.h0.PRECL.0710101-0765012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.11.14350-13871BP.cam2.h0.PRECT.0765101-0813012.nc : \
	heap/cropped/trace.11.14350-13871BP.cam2.h0.PRECC.0765101-0813012.nc \
	heap/cropped/trace.11.14350-13871BP.cam2.h0.PRECL.0765101-0813012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.12.13870-13101BP.cam2.h0.PRECT.0813101-0890012.nc : \
	heap/cropped/trace.12.13870-13101BP.cam2.h0.PRECC.0813101-0890012.nc \
	heap/cropped/trace.12.13870-13101BP.cam2.h0.PRECL.0813101-0890012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.13.13100-12901BP.cam2.h0.PRECT.0890101-0910012.nc : \
	heap/cropped/trace.13.13100-12901BP.cam2.h0.PRECC.0890101-0910012.nc \
	heap/cropped/trace.13.13100-12901BP.cam2.h0.PRECL.0890101-0910012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.14.12900-12501BP.cam2.h0.PRECT.0910101-0950012.nc : \
	heap/cropped/trace.14.12900-12501BP.cam2.h0.PRECC.0910101-0950012.nc \
	heap/cropped/trace.14.12900-12501BP.cam2.h0.PRECL.0910101-0950012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.15.12500-12001BP.cam2.h0.PRECT.0950101-1000012.nc : \
	heap/cropped/trace.15.12500-12001BP.cam2.h0.PRECC.0950101-1000012.nc \
	heap/cropped/trace.15.12500-12001BP.cam2.h0.PRECL.0950101-1000012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.16.12000-11701BP.cam2.h0.PRECT.1000101-1030012.nc : \
	heap/cropped/trace.16.12000-11701BP.cam2.h0.PRECC.1000101-1030012.nc \
	heap/cropped/trace.16.12000-11701BP.cam2.h0.PRECL.1000101-1030012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.17.11700-11301BP.cam2.h0.PRECT.1030101-1070012.nc : \
	heap/cropped/trace.17.11700-11301BP.cam2.h0.PRECC.1030101-1070012.nc \
	heap/cropped/trace.17.11700-11301BP.cam2.h0.PRECL.1030101-1070012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.18.11300-10801BP.cam2.h0.PRECT.1070101-1120012.nc : \
	heap/cropped/trace.18.11300-10801BP.cam2.h0.PRECC.1070101-1120012.nc \
	heap/cropped/trace.18.11300-10801BP.cam2.h0.PRECL.1070101-1120012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.19.10800-10201BP.cam2.h0.PRECT.1120101-1180012.nc : \
	heap/cropped/trace.19.10800-10201BP.cam2.h0.PRECC.1120101-1180012.nc \
	heap/cropped/trace.19.10800-10201BP.cam2.h0.PRECL.1120101-1180012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.20.10200-09701BP.cam2.h0.PRECT.1180101-1230012.nc : \
	heap/cropped/trace.20.10200-09701BP.cam2.h0.PRECC.1180101-1230012.nc \
	heap/cropped/trace.20.10200-09701BP.cam2.h0.PRECL.1180101-1230012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.21.09700-09201BP.cam2.h0.PRECT.1230101-1280012.nc : \
	heap/cropped/trace.21.09700-09201BP.cam2.h0.PRECC.1230101-1280012.nc \
	heap/cropped/trace.21.09700-09201BP.cam2.h0.PRECL.1230101-1280012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.22.09200-08701BP.cam2.h0.PRECT.1280101-1330012.nc : \
	heap/cropped/trace.22.09200-08701BP.cam2.h0.PRECC.1280101-1330012.nc \
	heap/cropped/trace.22.09200-08701BP.cam2.h0.PRECL.1280101-1330012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.23.08700-08501BP.cam2.h0.PRECT.1330101-1350012.nc : \
	heap/cropped/trace.23.08700-08501BP.cam2.h0.PRECC.1330101-1350012.nc \
	heap/cropped/trace.23.08700-08501BP.cam2.h0.PRECL.1330101-1350012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.24.08500-08001BP.cam2.h0.PRECT.1350101-1400012.nc : \
	heap/cropped/trace.24.08500-08001BP.cam2.h0.PRECC.1350101-1400012.nc \
	heap/cropped/trace.24.08500-08001BP.cam2.h0.PRECL.1350101-1400012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.25.08000-07601BP.cam2.h0.PRECT.1400101-1440012.nc : \
	heap/cropped/trace.25.08000-07601BP.cam2.h0.PRECC.1400101-1440012.nc \
	heap/cropped/trace.25.08000-07601BP.cam2.h0.PRECL.1400101-1440012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.26.07600-07201BP.cam2.h0.PRECT.1440101-1480012.nc : \
	heap/cropped/trace.26.07600-07201BP.cam2.h0.PRECC.1440101-1480012.nc \
	heap/cropped/trace.26.07600-07201BP.cam2.h0.PRECL.1440101-1480012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.27.07200-06701BP.cam2.h0.PRECT.1480101-1530012.nc : \
	heap/cropped/trace.27.07200-06701BP.cam2.h0.PRECC.1480101-1530012.nc \
	heap/cropped/trace.27.07200-06701BP.cam2.h0.PRECL.1480101-1530012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.28.06700-06201BP.cam2.h0.PRECT.1530101-1580012.nc : \
	heap/cropped/trace.28.06700-06201BP.cam2.h0.PRECC.1530101-1580012.nc \
	heap/cropped/trace.28.06700-06201BP.cam2.h0.PRECL.1530101-1580012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.29.06200-05701BP.cam2.h0.PRECT.1580101-1630012.nc : \
	heap/cropped/trace.29.06200-05701BP.cam2.h0.PRECC.1580101-1630012.nc \
	heap/cropped/trace.29.06200-05701BP.cam2.h0.PRECL.1580101-1630012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.30.05700-05001BP.cam2.h0.PRECT.1630101-1700012.nc : \
	heap/cropped/trace.30.05700-05001BP.cam2.h0.PRECC.1630101-1700012.nc \
	heap/cropped/trace.30.05700-05001BP.cam2.h0.PRECL.1630101-1700012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.31.05000-04001BP.cam2.h0.PRECT.1700101-1800012.nc : \
	heap/cropped/trace.31.05000-04001BP.cam2.h0.PRECC.1700101-1800012.nc \
	heap/cropped/trace.31.05000-04001BP.cam2.h0.PRECL.1700101-1800012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.32.04000-03201BP.cam2.h0.PRECT.1800101-1880012.nc : \
	heap/cropped/trace.32.04000-03201BP.cam2.h0.PRECC.1800101-1880012.nc \
	heap/cropped/trace.32.04000-03201BP.cam2.h0.PRECL.1800101-1880012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.33.03200-02401BP.cam2.h0.PRECT.1880101-1960012.nc : \
	heap/cropped/trace.33.03200-02401BP.cam2.h0.PRECC.1880101-1960012.nc \
	heap/cropped/trace.33.03200-02401BP.cam2.h0.PRECL.1880101-1960012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.34.02400-01401BP.cam2.h0.PRECT.1960101-2060012.nc : \
	heap/cropped/trace.34.02400-01401BP.cam2.h0.PRECC.1960101-2060012.nc \
	heap/cropped/trace.34.02400-01401BP.cam2.h0.PRECL.1960101-2060012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.35.01400-00401BP.cam2.h0.PRECT.2060101-2160012.nc : \
	heap/cropped/trace.35.01400-00401BP.cam2.h0.PRECC.2060101-2160012.nc \
	heap/cropped/trace.35.01400-00401BP.cam2.h0.PRECL.2060101-2160012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

heap/cropped/trace.36.400BP-1990CE.cam2.h0.PRECT.2160101-2204012.nc : \
	heap/cropped/trace.36.400BP-1990CE.cam2.h0.PRECC.2160101-2204012.nc \
	heap/cropped/trace.36.400BP-1990CE.cam2.h0.PRECL.2160101-2204012.nc \
	scripts/add_PRECC_PRECL.sh
	$(PRECT_RULE)

