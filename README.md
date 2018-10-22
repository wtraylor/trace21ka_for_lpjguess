Prepare TraCE-21ka monthly data as LPJ-GUESS drivers
====================================================

Requirements
------------

- A _make_ implementation, e.g. `gmake`.

- Python. 
<!-- TODO: which version? -->

On Ubuntu run `sudo apt install make`

How to Use
----------

1) Download the TraCE-21ka monthly datasets for the CCSM3 variables `PRECC`, `PRECL`, `TREFHT`, `CLOUD`, and `FSDS` for your time period from [earthsystemgrid.org](https://www.earthsystemgrid.org/dataset/ucar.cgd.ccsm3.trace.html).

2) Customize `settings.yaml` to your own needs.

3) Run `make` from within this directory (where `Makefile` resides).

By default, the script expects the files in the subdirectory `trace_original`.
You can copy your downloaded files there or create a symbolic link (on Linux: `ln -sv /path/to/trace trace_original` within this directory).
You can also supply the path as an argument: `make TRACE_ORIG=/path/to/trace`

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

Authors
-------

Main author: [Wolfgang Traylor](mailto:wolfgang.pappa@senckenberg.de)

Thanks to: Christian Werner, Matthew Forrest
