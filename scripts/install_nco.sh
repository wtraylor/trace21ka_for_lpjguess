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

# Try to find `conda` in the default install directory.
MINICONDA_BIN=$(readlink -f miniconda3/bin)
if [ -d "$MINICONDA_BIN" ];then
  PATH="$MINICONDA_BIN:$PATH"
  green "Found Miniconda installation in '$MINICONDA_BIN'."
else
  red "Could not find Miniconda in path '$MINICONDA_BIN'."
  (>&2 echo "Have you run the script 'install_miniconda.sh'?")
  exit 1
fi

if [ -x "$MINICONDA_BIN/ncks" ]; then
    green "NCO is already installed here: \"$MINICONDA_BIN\""
    exit 0
fi

green 'Installing nco locally with conda...'
conda install -c conda-forge nco

if [ "$?" == 0 ]; then
  # Check `ncks` executable vicariously for the whole NCO installation.
  if [ -x "$MINICONDA_BIN/ncks" ]; then
    green 'Successfully installed NCO.'
    exit 0
  else
    red 'NCO was not installed.'
    exit 1
  fi
else
  red 'An error occurred in the NCO installer.'
  exit 1
fi
