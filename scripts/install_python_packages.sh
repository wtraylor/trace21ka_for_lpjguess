#!/bin/bash

## Echo in green color
function green() {
  # We need to use the system path to `tput` because Miniconda installs its own `tput` binary.
  /usr/bin/tput setaf 2
  (>&2 echo $*)
  /usr/bin/tput sgr0
}

## Echo in red color
function red() {
  # We need to use the system path to `tput` because Miniconda installs its own `tput` binary.
  /usr/bin/tput setaf 1
  (>&2 echo $*)
  /usr/bin/tput sgr0
}

# See if Miniconda is installed.
MINICONDA_BIN=$(readlink -f miniconda3/bin)
if [ -d "$MINICONDA_BIN" ];then
  PATH="$MINICONDA_BIN:$PATH"
  green "Found Miniconda installation in '$MINICONDA_BIN'."
else
  red "Could not find Miniconda in path '$MINICONDA_BIN'."
  (>&2 echo "Have you run the script 'install_miniconda.sh'?")
  exit 1
fi

# Try to find `pip` in the default install directory.
PIP="$MINICONDA_BIN/pip"
if [ ! -x "$PIP" ]; then
	red "\`pip\` does not seem to be installed in Miniconda."
	red "Try to install Miniconda again."
	exit 1
fi

# Add any new python dependencies here (space-separated:
PYTHON_PACKAGES="xarray"

green 'Installing Python packages: '
# Insert line breaks into package list
green -e $(echo $PYTHON_PACKAGES | sed 's; ;\n;g')

"$PIP" install "$PYTHON_PACKAGES"
green 'Done.'
