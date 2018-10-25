#!/bin/bash

## Echo in green color
function green() {
  tput setaf 2
  (>&2 echo $*)
  tput sgr0
}

## Echo in red color
function red() {
  tput setaf 1
  (>&2 echo $*)
  tput sgr0
}

if [ -z "$CONDA_PREFIX" ]; then
  CONDA_PREFIX="$(readlink -f miniconda3)"
fi

# Delete old installation
rm --recursive --force "$CONDA_PREFIX"

CONDA_INSTALLER='Miniconda3-latest-Linux-x86_64.sh'

green 'Downloading latest Miniconda release for 64bit Linux...'
if [ ! -s "$CONDA_INSTALLER" ]; then
  wget "https://repo.continuum.io/miniconda/$CONDA_INSTALLER"
else
  green "Already downloaded '$CONDA_INSTALLER'."
fi

if [ ! -f "$CONDA_INSTALLER" ]; then
  red "Cannot find downloaded file \"$CONDA_INSTALLER\"."
  red 'Aborting.'
  exit 1
fi

green "Installing Miniconda to \"$CONDA_PREFIX\"..."
# -b           run install in batch mode (without manual intervention),
#              it is expected the license terms are agreed upon
# -f           no error if install prefix already exists
# -p PREFIX    install prefix, defaults to $PREFIX, must not contain spaces.
sh "$CONDA_INSTALLER" -p "$CONDA_PREFIX"

if [ "$?" == 0 ]; then
  green 'Successfully installed Miniconda.'
  exit 0
else
  red 'An error occurred in the Miniconda installer.'
  exit 1
fi
