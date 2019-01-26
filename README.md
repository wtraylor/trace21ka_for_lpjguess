Prepare TraCE-21ka monthly data as LPJ-GUESS drivers
====================================================

Motivation
----------

TODO

Description
-----------

This script bundle downscales and bias-corrects the monthly TraCE-21ka paleoclimate dataset (He 2011) and prepares NetCDF files that are readable as driving data by LPJ-GUESS.
Bias-correction is based on the CRUNCEP 5 dataset of modern monthly climate between 1900 and 2013 in 0.5°x0.5° grid cell resolution.<!--TODO: Citation-->

<!--TODO:
- Algorithm for downscaling
- Why downscaling? ⇒ generate orthographical details
- How to interpret the high resolution: Anything that’s not elevation is an artefact.
- How are changing coast lines handled?
-->

Prerequisites
-------------

- A Linux terminal on a 64bit machine.

- Optional: A Miniconda installation <https://www.anaconda.com/download/>

Usage
-----

### Download Data

Important: Do not change the original file names!

- Download the TraCE-21ka monthly datasets for the CCSM3 variables `PRECC`, `PRECL`, `TREFHT`, `CLOUD`, and `FSDS` for your time period from [earthsystemgrid.org](https://www.earthsystemgrid.org/dataset/ucar.cgd.ccsm3.trace.html).

- Download the global monthly CRU TS 4.01 data set in 0.5° resolution as the original zip files from [crudata.uea.ac.uk](https://crudata.uea.ac.uk/cru/data/hrg/). Save all files with their original name in one directory. You will need the following variables: `pre`, `tmp`, `wet`

- Download the CRU JRA-55 precipitation (`pre`) data set from [vesg.ipsl.upmc.fr](https://vesg.ipsl.upmc.fr/thredds/catalog/work/p529viov/crujra/catalog.html). Only the years 1958 to 2017 are used. You can use the download script `make download_crujra` (requires `wget` to be installed).

### Running the script

1) Customize `options.yaml` to your own needs.
Be careful not to keep other files in your "heap" or "output" directory since they will be deleted with `make clean`.

2) Open a terminal in the root of this repository (where the `Makefile` lies).

  - If you don’t have Miniconda or Anaconda installed in your system yet, you can install `miniconda` through your package manager or download it manually (<https://conda.io/miniconda.html>). Alternatively run `make install_conda`, which will download and extract a Miniconda installation for Linux 64-bit into a subdirectory.

  - Run `make create_environment`. This will create a local Conda environment for this little project in the subdirectory `conda_environment` and install all dependencies.

  - Then you can run the actual script: `make run`. If you encounter problems or need to interrupt the script, you can restart it again. But if you change something in `options.yaml`, you should probably run `make clean` 

  - When you are done, you can delete the environment with `make delete_environment` and clean up the files with `make clean`.

### Running LPJ-GUESS

TODO: Generate instruction file or give an example.

Run LPJ-GUESS with the CF input module: `guess -input cf "/path/to/my/instruction_file.ins"`

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

Related Projects
----------------

TODO

Authors
-------

Main author: [Wolfgang Traylor](mailto:wolfgang.pappa@senckenberg.de), Senckenberg Biodiversity and Climate Research Institute, Frankfurt, Germany

Thanks to Christian Werner and Johan Liakka for their example script.
Thanks to Matthew Forrest for a few tips.

License
-------

[MIT](LICENSE)

References
----------

- He, Feng. 2011. “Simulating Transient Climate Evolution of the Last Deglaciation with Ccsm 3.” PhD thesis, University of Wisconsin-Madison.
