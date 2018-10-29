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

- `wget`

- A working internet connection for the automatic download of [Miniconda](https://conda.io/miniconda.html) and Python packages.

On Ubuntu run `sudo apt install make wget`

Python and all other necessary software ([nco](http://nco.sourceforge.net/), [cdo](https://code.mpimet.mpg.de/projects/cdo)) are installed through Miniconda automatically and run from local binaries.
This way, no system-wide installations are required.

How to Use
----------

1) Download the TraCE-21ka monthly datasets for the CCSM3 variables `PRECC`, `PRECL`, `TREFHT`, `CLOUD`, and `FSDS` for your time period from [earthsystemgrid.org](https://www.earthsystemgrid.org/dataset/ucar.cgd.ccsm3.trace.html).

2) Customize `options.yaml` to your own needs.

3) Run `make` from within this directory (where `Makefile` resides).
Only run `make` from an interactive shell.

By default, the script expects the files in the subdirectory `trace_original`.
You can copy your downloaded files there or create a symbolic link (on Linux: `ln -sv /path/to/trace trace_original` within this directory).
You can also supply a custom path in `options.yaml`.

There will be some temporary files produced.
They are stored in the “heap” directory.
It defaults to `heap/` in the root of the Git repository, which is created when needed.
You can specify it in the `Makefile` or as a parameter to the call `make HEAP=/path/to/heap`.
Note that there should be enough free space available.

File Structure
--------------

- `cruncep/`: Monthly means of the CRUNCEP5 data set from 1900 to 2013.
  **TODO:** Citation, where doe the data come from exactly?
- `heap/`: Automatically created directory for temporary files. Can be customized.
- `scripts/`:
    + `add_modern_monthly_PRECC_PRECL.sh`: Add the CCSM3 precipitation variables `PRECC` and `PRECL` to `PRECT`.
    + `aggregate_modern_trace.py`: Create monthly means of the TraCE-21ka output of most recent times and write it to NetCDF files in the heap.
    + `install_miniconda.sh`: Download and install [Miniconda](https://conda.io/miniconda.html) in the subdirectory `miniconda3/`.
    + `install_nco.sh`: Install [NCO](http://nco.sourceforge.net/) locally through `conda`.
    + `install_python_packages.sh`: Install all necessary Python packages locally in `miniconda3/` using `pip`.

Project Outline
---------------

- [ ] Calculate monthly bias for all grid cells against modern CRUNCEP.
- [ ] Calculate `PRECT` as `PRECC + PRECL`.
- [ ] Crop TraCE data to specified region.
- [ ] Split dataset into 100 years files.
- [ ] Downscale TraCE dataset to 0.5° grid resolution.
- [ ] Mask oceans and glaciers, based on ICE-5G.
- [ ] Bias-correct all files.
- [ ] Calculate wet days, based on modern monthly wet days. Store them as `wet` variable in precipitation file.
- [ ] Set standard names for all NetCDF variables.
- [ ] Use land IDs instead of lon/lat for LPJ-GUESS (for performance).
- [ ] Compress output files.
- [ ] Provide example LPJ-GUESS instruction file.

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
