help:
	@echo 'Please choose a target for the make command.'
	@echo 'See README.md for your options.'

###############################################################################
## VARIABLES
###############################################################################

# TODO: Use specific version and not latest version.
# TODO: Download 32 on 32-bit architectures.
CONDA_INSTALLER = Miniconda3-latest-Linux-x86_64.sh

# The root directory of the local Miniconda installation.
MINICONDA = miniconda3

# The directory of binaries in the Miniconda installation.
# If `conda` is found in the PATH, use the existing installation, otherwise
# use local installation in project directory.
CHECK_CONDA=$(shell which conda 2>/dev/null)
ifeq "$(CHECK_CONDA)" ""
	export PATH := ${MINICONDA}/bin:$(PATH)
endif

# The name of our Conda environment. This must match the "name" attribute
# in `environment.yml`.
ENV := trace_for_guess

###############################################################################
## INSTALLATION
###############################################################################

# - We use `test "$$(which conda)"` to check if the conda binary is in the
#   PATH (i.e. either in the system installation or locally in $MINICONDA).
#   If `conda` cannot be found, `which` will create an error message and
#   the rule will be aborted.

# We `touch` the installed files (the Make targets) so that they are marked as
# up-to-date even if the installation command doesn’t change them (because
# they are already installed).

# For some reasen, the download with `wget` did not always work reliably. With
# `curl` it is no problem.
$(CONDA_INSTALLER) :
	@echo "Downloading Miniconda install script..."
	@curl "https://repo.continuum.io/miniconda/$(CONDA_INSTALLER)" > \
		$(CONDA_INSTALLER)
	@touch --no-create $(CONDA_INSTALLER)

.PHONY: install_conda
# Miniconda installer command line arguments:
# -p PREFIX    install prefix, defaults to $PREFIX, must not contain spaces.
# -u           update an existing installation
install_conda: $(CONDA_INSTALLER)
	@echo "Installing Miniconda to '$(MINICONDA)'..."
	@sh "$(CONDA_INSTALLER)" -u -p "$(MINICONDA)"

.PHONY: create_environment
create_environment:
	@test "$$(which conda)"
	@echo 'Creating local conda environment...'
	@conda env create --file 'environment.yml' --force
	@echo 'Conda environment succesfully created:'
	@conda env list

.PHONY: run
run:
	@test "$$(which activate)"
	@test "$$(which python)"
	@source activate  $(ENV) && python 'prepare_trace_for_guess'

.PHONY: delete_environment
delete_environment:
	@echo 'Deleting conda environment.'
	@test "$$(which conda)"
	@conda remove $(ENV)

.PHONY: download_crujra
download_crujra:
	@test "$$(which activate)"
	@test "$$(which python)"
	@source activate  $(ENV) && python 'trace_for_guess/download_crujra.py'

.PHONY: clean
clean:
	@test "$$(which python)"
	@source activate  $(ENV) && python 'trace_for_guess/clean.py'
