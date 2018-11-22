###############################################################################
## ORIGINAL TRACE FILES
###############################################################################

PRECC := trace.*PRECC*.nc
PRECL := trace.*PRECL*.nc
TREFHT := trace.*TREFHT*.nc

# All original TraCE files. TODO: Add rest of the files.
ALL_ORIG = $(wildcard trace_orig/$(PRECC)) $(wildcard trace_orig/$(PRECL)) $(wildcard trace_orig/$(TREFHT))

###############################################################################
## ORIGINAL CRU FILES
###############################################################################

# Select all CRU files that follow the standard naming and filter then for
# specific variables. We only select the time frame 1901 to 1990.
# The command to find all relevant zipped CRU files is this:
# `find cru_orig/ -name 'cru_ts4\.01\.19[0-8]1\.19[1-9]0\.[a-z]*\.dat\.nc\.gz'`
CRU_ALL = cru_orig/cru_ts4.01.1921.1930.pre.dat.nc.gz \
					cru_orig/cru_ts4.01.1941.1950.wet.dat.nc.gz \
					cru_orig/cru_ts4.01.1921.1930.tmp.dat.nc.gz \
					cru_orig/cru_ts4.01.1931.1940.pre.dat.nc.gz \
					cru_orig/cru_ts4.01.1901.1910.tmp.dat.nc.gz \
					cru_orig/cru_ts4.01.1911.1920.pre.dat.nc.gz \
					cru_orig/cru_ts4.01.1961.1970.tmp.dat.nc.gz \
					cru_orig/cru_ts4.01.1931.1940.tmp.dat.nc.gz \
					cru_orig/cru_ts4.01.1921.1930.wet.dat.nc.gz \
					cru_orig/cru_ts4.01.1971.1980.wet.dat.nc.gz \
					cru_orig/cru_ts4.01.1951.1960.tmp.dat.nc.gz \
					cru_orig/cru_ts4.01.1911.1920.tmp.dat.nc.gz \
					cru_orig/cru_ts4.01.1971.1980.tmp.dat.nc.gz \
					cru_orig/cru_ts4.01.1981.1990.tmp.dat.nc.gz \
					cru_orig/cru_ts4.01.1951.1960.wet.dat.nc.gz \
					cru_orig/cru_ts4.01.1981.1990.pre.dat.nc.gz \
					cru_orig/cru_ts4.01.1901.1910.pre.dat.nc.gz \
					cru_orig/cru_ts4.01.1981.1990.wet.dat.nc.gz \
					cru_orig/cru_ts4.01.1941.1950.tmp.dat.nc.gz \
					cru_orig/cru_ts4.01.1901.1910.wet.dat.nc.gz \
					cru_orig/cru_ts4.01.1941.1950.pre.dat.nc.gz \
					cru_orig/cru_ts4.01.1911.1920.wet.dat.nc.gz \
					cru_orig/cru_ts4.01.1931.1940.wet.dat.nc.gz \
					cru_orig/cru_ts4.01.1951.1960.pre.dat.nc.gz \
					cru_orig/cru_ts4.01.1961.1970.wet.dat.nc.gz \
					cru_orig/cru_ts4.01.1971.1980.pre.dat.nc.gz \
					cru_orig/cru_ts4.01.1961.1970.pre.dat.nc.gz
CRU_PRE = $(shell echo $(CRU_ALL) | sed 's/ /\n/g' | \
					grep 'pre')
CRU_TMP = $(shell echo $(CRU_ALL) | sed 's/ /\n/g' | \
					grep 'tmp')
CRU_WET = $(shell echo $(CRU_ALL) | sed 's/ /\n/g' | \
					grep 'wet')

CRUJRA = crujra_orig/crujra.V1.1.5d.pre.1958.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1959.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1960.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1961.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1962.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1963.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1964.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1965.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1966.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1967.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1968.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1969.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1970.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1971.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1972.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1973.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1974.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1975.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1976.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1977.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1978.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1979.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1980.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1981.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1982.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1983.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1984.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1985.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1986.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1987.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1988.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1989.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1990.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1991.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1992.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1993.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1994.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1995.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1996.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1997.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1998.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.1999.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2000.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2001.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2002.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2003.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2004.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2005.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2006.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2007.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2008.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2009.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2010.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2011.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2012.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2013.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2014.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2015.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2016.365d.noc.nc.gz\
		 crujra_orig/crujra.V1.1.5d.pre.2017.365d.noc.nc.gz

###############################################################################
## TARGET FILES
###############################################################################

SYMLINKS = cru_orig heap output trace_orig

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

.PHONY: all
# TODO: This is only a stub so far.
all : $(SYMLINKS) $(OUTPUT_FILES)
	@echo "Not implemented yet."

.PHONY: debias
debias : $(SYMLINKS) $(SPLIT_FILES) $(DEBIASED_TREFHT) $(DEBIASED_PRECT)
	@echo "Debiasing finished."

.PHONY: downscale
downscale : $(SYMLINKS) $(SPLIT_FILES) $(DOWNSCALED_FILES)
	@echo "Downscaling finished."

.PHONY: split
split : $(SYMLINKS) $(SPLIT_FILES)
	@echo "Splitting finished."

.PHONY: crop
# This target depends on all original TraCE files being cropped in the folder
# 'heap/cropped/'.
crop : $(SYMLINKS) $(CROPPED_FILES)
	@echo "Cropping finished."

.PHONY: clean
# Be cautious: Only remove those files and directories that are also created
# by this script.
# NCO can produce temporary files like this one:
# 'trace.01.22000-20001BP.cam2.h0.PRECC.0000101-0200012.nc.pid31368.ncks.tmp'
# Those temporary NCO files are removed with a `find` command.
# Append `exit 0` to the `rm` command so that the return code is always
# SUCCESS. Otherwise the rule fails if `rm` doesn’t find a file/directory.
# Also remove the symbolic links "trace_orig" and "cru_orig".
clean :
	@rm --verbose \
		heap/bias_*.nc \
		heap/cropped/trace*.nc \
		heap/cru_cat/*.nc \
		heap/cru_mean/*.nc \
		heap/cru_orig/*.nc \
		heap/crujra_orig/*.nc \
		heap/cru_regrid/*.nc \
		heap/debiased/trace.*.nc \
		heap/downscaled/**trace*.nc \
		heap/grid_template.nc \
		heap/modern_trace_*.nc \
		heap/split/**.nc \
		PET0.RegridWeightGen.Log \
		2>/dev/null; \
		exit 0
	@find heap -name '*.nc.pid*.nc*.tmp' -delete -print 2>/dev/null; exit 0
	@rm --dir --verbose \
		heap/cropped \
		heap/cru_cat \
		heap/cru_mean \
		heap/cru_orig \
		heap/crujra_orig \
		heap/cru_regrid \
		heap/debiased \
		heap/downscaled \
		heap/split \
		2>/dev/null; \
		exit 0
	@rm --verbose \
		cru_orig \
		crujra_orig \
		heap \
		output \
		trace_orig \
		2>/dev/null; \
		exit 0

clean_install : clean
	@rm --recursive --verbose \
		$(MINICONDA) \
		$(CONDA_INSTALLER)

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

scripts/debias.py : $(PYTHON) $(TERMCOLOR) $(XARRAY)

scripts/rescale.py : $(PYTHON) $(TERMCOLOR) $(YAML) $(NCO) options.yaml heap/grid_template.nc

scripts/symlink_dir.py : $(PYTHON) $(TERMCOLOR) $(YAML) options.yaml

###############################################################################
## SYMLINK INPUT & OUTPUT DIRECTORIES
###############################################################################

cru_orig : scripts/symlink_dir.py options.yaml
	@$(PYTHON) scripts/symlink_dir.py '$@'

crujra_orig : scripts/symlink_dir.py options.yaml
	@$(PYTHON) scripts/symlink_dir.py '$@'

heap : scripts/symlink_dir.py options.yaml
	@$(PYTHON) scripts/symlink_dir.py '$@'

output : scripts/symlink_dir.py options.yaml
	@$(PYTHON) scripts/symlink_dir.py '$@'

trace_orig : scripts/symlink_dir.py options.yaml
	@$(PYTHON) scripts/symlink_dir.py '$@'

###############################################################################
## DECOMPRESS CRU FILES
###############################################################################

# `pv` ("pipe viewer") shows the progress.
define UNZIP_RULE =
@mkdir --parents 'heap/cru_orig'
@echo "Unzipping $<..."
@pv $< | gunzip --verbose --decompress --synchronous --stdout > $@
endef

heap/cru_orig/%.nc : cru_orig/%.nc.gz
	$(UNZIP_RULE)

heap/crujra_orig/%.nc : crujra_orig/%.nc.gz
	$(UNZIP_RULE)

###############################################################################
## CONCATENATE AND AGGREGATE CRU FILES
###############################################################################

heap/cru_cat/pre.nc : cru_orig $(patsubst cru_orig/%.nc.gz, heap/cru_orig/%.nc, $(CRU_PRE)) $(NCO)
	@mkdir --parents 'heap/cru_cat'
	@echo "Concatenating CRU precipitation..."
	@env PATH="$(BIN):$(PATH)" \
	  ncrcat $(filter heap/cru_orig/%, $^) $@

heap/cru_cat/tmp.nc : cru_orig $(patsubst cru_orig/%.nc.gz, heap/cru_orig/%.nc, $(CRU_TMP)) $(NCO)
	@mkdir --parents 'heap/cru_cat'
	@echo "Concatenating CRU temperature..."
	@env PATH="$(BIN):$(PATH)" \
	  ncrcat $(filter heap/cru_orig/%, $^) $@

heap/cru_cat/wet.nc : cru_orig $(patsubst cru_orig/%.nc.gz, heap/cru_orig/%.nc, $(CRU_WET)) $(NCO)
	@mkdir --parents 'heap/cru_cat'
	@echo "Concatenating CRU wet days..."
	@env PATH="$(BIN):$(PATH)" \
	  ncrcat $(filter heap/cru_orig/%, $^) $@

###############################################################################
## AGGREGATE CRU FILES
###############################################################################

# Calculate the monthly averages over all years so that we have only 12 values
# in each file.

heap/cru_mean/%.nc : heap/cru_cat/%.nc
	@mkdir --parents 'heap/cru_mean'
	@echo "Calculating monthly means over total time period in CRU:"
	@echo "$< => $@"
	@env PATH="$(BIN):$(PATH)" \
		cdo ymonmean $< $@

# Calculate the day-to-day standard deviation of daily precipitation sum as
# monthly means.
heap/crujra/monthly_std.nc : $(patsubst crujra_orig/%.nc.gz, heap/crujra_orig/%.nc, $(CRUJRA)) scripts/aggregate_crujra.sh
	@env PATH="$(BIN):$(PATH)" \
		scripts/aggregate_crujra.sh

###############################################################################
## REGRID CRU FILES
###############################################################################

heap/cru_regrid/%.nc : heap/cru_mean/%.nc scripts/rescale.py
	@env PATH="$(BIN):$(PATH)" $(PYTHON) scripts/rescale.py $< $@

###############################################################################
## AGGREGATE MODERN TRACE DATA
###############################################################################

heap/modern_trace_TREFHT.nc : trace_orig scripts/aggregate_modern_trace.py
	@$(PYTHON) scripts/aggregate_modern_trace.py TREFHT

heap/modern_trace_FSDS.nc : trace_orig scripts/aggregate_modern_trace.py
	@$(PYTHON) scripts/aggregate_modern_trace.py FSDS

heap/modern_trace_PRECL.nc : trace_orig scripts/aggregate_modern_trace.py
	@$(PYTHON) scripts/aggregate_modern_trace.py PRECL

heap/modern_trace_PRECC.nc : trace_orig scripts/aggregate_modern_trace.py
	@$(PYTHON) scripts/aggregate_modern_trace.py PRECC

heap/modern_trace_PRECT.nc : heap/modern_trace_PRECL.nc heap/modern_trace_PRECC.nc $(NCO) scripts/add_PRECC_PRECL.sh
	@env PATH="$(BIN):$(PATH)" \
		scripts/add_PRECC_PRECL.sh \
		heap/modern_trace_PRECC.nc \
		heap/modern_trace_PRECL.nc \
		heap/modern_trace_PRECT.nc

###############################################################################
## REGRID MODERN TRACE DATA
###############################################################################

heap/modern_trace_FSDS_regrid.nc : heap/modern_trace_FSDS.nc scripts/rescale.py
	@env PATH="$(BIN):$(PATH)" $(PYTHON) scripts/rescale.py $< $@

heap/modern_trace_PRECT_regrid.nc : heap/modern_trace_PRECT.nc scripts/rescale.py
	@env PATH="$(BIN):$(PATH)" $(PYTHON) scripts/rescale.py $< $@

heap/modern_trace_TREFHT_regrid.nc : heap/modern_trace_TREFHT.nc scripts/rescale.py
	@env PATH="$(BIN):$(PATH)" $(PYTHON) scripts/rescale.py $< $@

###############################################################################
## CALCULATE BIAS
###############################################################################

heap/bias_PRECT.nc : heap/cru_regrid/pre.nc heap/modern_trace_PRECT_regrid.nc scripts/calculate_bias.py
	@$(PYTHON) scripts/calculate_bias.py "PRECT"

heap/bias_TREFHT.nc : heap/cru_regrid/tmp.nc heap/modern_trace_TREFHT_regrid.nc scripts/calculate_bias.py
	@$(PYTHON) scripts/calculate_bias.py "TREFHT"

###############################################################################
## CROPPING
###############################################################################

# For each original TraCE file there is a rule to create the corresponding
# cropped NetCDF file (with the same name) in heap/cropped.
heap/cropped/%.nc : trace_orig/%.nc scripts/crop_file.py
	@mkdir --parents heap/cropped
	@env PATH="$(BIN):$(PATH)" $(PYTHON) scripts/crop_file.py $< $@

heap/grid_template.nc : heap/cru_mean/tmp.nc scripts/crop_file.py
	@env PATH="$(BIN):$(PATH)" $(PYTHON) scripts/crop_file.py $< $@

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
## DOWNSCALE TRACE FILES
###############################################################################

# For every split file, there is a downscaled target.
heap/downscaled/%.nc : heap/split/%.nc scripts/rescale.py
	@mkdir --parents heap/downscaled
	@env PATH="$(BIN):$(PATH)" $(PYTHON) scripts/rescale.py $< $@

###############################################################################
## DEBIAS TRACE FILES
###############################################################################

$(DEBIASED_PRECT) : heap/debiased/%.nc : heap/downscaled/%.nc heap/bias_PRECT.nc scripts/debias.py
	@mkdir --parents 'heap/debiased'
	@$(PYTHON) scripts/debias.py $< $@

$(DEBIASED_TREFHT) : heap/debiased/%.nc : heap/downscaled/%.nc heap/bias_TREFHT.nc scripts/debias.py
	@mkdir --parents 'heap/debiased'
	@$(PYTHON) scripts/debias.py $< $@

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

