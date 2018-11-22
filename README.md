Prepare TraCE-21ka monthly data as LPJ-GUESS drivers
====================================================

Introduction
------------

This script bundle downscales and bias-corrects the monthly TraCE-21ka paleoclimate dataset (He 2011) and prepares NetCDF files that are readable as driving data by LPJ-GUESS.
Bias-correction is based on the CRUNCEP 5 dataset of modern monthly climate between 1900 and 2013 in 0.5°x0.5° grid cell resolution.<!--TODO: Citation-->

<!--TODO:
- Algorithm for downscaling
- Why downscaling? ⇒ generate orthographical details
- How to interpret the high resolution: Anything that’s not elevation is an artefact.
- How are changing coast lines handled?
-->

Requirements
------------

- A Linux terminal on a 64bit machine.

- A _make_ implementation, e.g. `gmake`.

- Some command line tools: `gunzip`, `pv`, `wget`

- A working internet connection for the automatic download of [Miniconda](https://conda.io/miniconda.html) and Python packages.

On Ubuntu run `sudo apt install make wget`

Python and all other necessary software ([nco](http://nco.sourceforge.net/), [cdo](https://code.mpimet.mpg.de/projects/cdo)) are installed through Miniconda automatically and run from local binaries.
This way, no system-wide installations are required.

How to Use
----------

1) Download the data sets. Do not change the original file names.

    - Download the TraCE-21ka monthly datasets for the CCSM3 variables `PRECC`, `PRECL`, `TREFHT`, `CLOUD`, and `FSDS` for your time period from [earthsystemgrid.org](https://www.earthsystemgrid.org/dataset/ucar.cgd.ccsm3.trace.html). All files need to be in one directory with their original file name.

    - Download the global monthly CRU TS 4.01 data set in 0.5° resolution as the original zip files from [crudata.uea.ac.uk](https://crudata.uea.ac.uk/cru/data/hrg/). Save all files with their original name in one directory. You will need the following variables: `pre`, `tmp`, `wet`

    - Download the CRU JRA-55 precipitation (`pre`) data set from [vesg.ipsl.upmc.fr](https://vesg.ipsl.upmc.fr/thredds/catalog/work/p529viov/crujra/catalog.html). Only the years 1958 to 2017 are used. You can use the download script `scripts/download_crujra.py`. Have all files in one directory.

4) Customize `options.yaml` to your own needs.

5) Run `make` from within this directory (where `Makefile` resides).
Only run `make` from an interactive shell.

There will be some temporary files produced.
They are stored in the “heap” directory.
It needs a lot of free space.
You can create a symbolic link if you like to store the temporary files on another partition: `ln --force --symbolic /path/to/my/heap heap`

File Structure
--------------

- `heap/`: Directory for temporary files. This can be a symbolic link, too (see above).
- `scripts/`:
    + `add_PRECC_PRECL.sh`: Add the CCSM3 precipitation variables `PRECC` and `PRECL` to create a new file with `PRECT`.
	+ `aggregate_crujra.sh`: Create a NetCDF file with the mean monthly day-to-day standard deviation of precipitation from the CRU JRA dataset.
    + `aggregate_modern_trace.py`: Create monthly means of the TraCE-21ka output of most recent times and write it to NetCDF files in the heap.
    + `calculate_bias.py <VAR>`: Create a NetCDF file containing the monthly bias of TraCE compared to the CRUNCEP data.
	+ `debias.py`: TODO
	+ `cf_attributes.py`: TODO
	+ `download_crujra.py`: A little python script for downloading the required CRU JRA files. This is not automatically called by `make`.
	+ `rescale.py`: TODO
	+ `symlink_dir.py`: Create a symbolic link in the repository root that points to a directory with downloaded NetCDF files. The path to the this directory is specified in `options.yaml`.
	+ `wet_days.py`: TODO

Project Outline
---------------

- [ ] Fix the broken time dimension! It’s all set to zero.
- [x] Calculate monthly bias for all grid cells against modern CRUNCEP.
- [x] Calculate `PRECT` as `PRECC + PRECL`.
- [x] Crop TraCE data to specified region.
- [x] Split dataset into 100 years files.
- [x] Downscale TraCE dataset to 0.5° grid resolution.
- [ ] Improve regridding performance by saving und reusing the weight map.
- [ ] Add option to define custom grid resolution. 0.5° is just very high resolution!
- [ ] Mask oceans and glaciers, based on ICE-5G.
- [x] Bias-correct all files.
- [ ] Calculate wet days, based on modern monthly wet days. Store them as `wet` variable in precipitation file.
- [ ] Set standard names for all NetCDF variables.
- [ ] Use land IDs instead of lon/lat for LPJ-GUESS (for performance).
- [ ] Compress output files.
- [ ] Provide example LPJ-GUESS instruction file.
- [ ] Switch to more recent CRU 4.02

Design Questions
----------------

- Use land IDs or not? How much faster will LPJ-GUESS run? Land IDs have the disadvantage that you cannot easily plot the data file with standard NetCDF tools.

- How are wet days calculated exactly? ⇒ Lookup in publication.

- How shall we set the calendar?

- How to bias-correct radiation?
    + The radiation of TraCE-21ka shouldn’t be biased in any way because it is astronomically calculated.
    + Perhaps we need to bias-correct the cloud cover.

- Is it good to bias-correct precipitation with a simple quotient? ⇒ Compare Lorenz et al. (2016)

- Shall we install dependencies (nco, cdo, xarray, ...) locally or assume a system-wide installation?

Authors
-------

Main author: [Wolfgang Traylor](mailto:wolfgang.pappa@senckenberg.de)

Thanks to: Christian Werner, Matthew Forrest

References
----------

- He, Feng. 2011. “Simulating Transient Climate Evolution of the Last Deglaciation with Ccsm 3.” PhD thesis, University of Wisconsin-Madison.
