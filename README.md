Prepare TraCE-21ka monthly data as LPJ-GUESS drivers
====================================================

Motivation
----------

We want to use the transient monthly paleoclimate dataset [TraCE-21ka](http://www.cgd.ucar.edu/ccr/TraCE/) as climatic driving data for the DGVM [LPJ-GUESS](http://iis4.nateko.lu.se/lpj-guess/).

Bias-correction is necessary because present-day temperature and precipitation of the CCSM3 simulations diverge tremendously from measurements in some regions (e.g. NE-Siberia).
We want to downscale the data together with bias-correcting it because this way orographic effects are represented (e.g. higher altitudes are colder).

Description
-----------

This script bundle **downscales** and **bias-corrects** the monthly TraCE-21ka paleoclimate dataset [He 2011](http://www.aos.wisc.edu/uwaosjournal/Volume15/He_PhD_Thesis.pdf) and prepares NetCDF files that are readable as driving data by LPJ-GUESS.

Bias-correction of temperature and precipitation is based on the CRU dataset of modern monthly climate between 1900 and 1990 in 0.5° by 0.5° grid cell resolution.<!--TODO: Citation-->

The TraCE files are regridded to match the CRU resolution using bilinear interpolation.
Note that the higher resolution in of itself does not provide any gain in information.
It only helps to create orographic/altitudinal effects.

The **chunking** of the output NetCDF files is optimized for LPJ-GUESS input, i.e. for reading each grid cell separately for the whole time series.
See [this](https://www.unidata.ucar.edu/blogs/developer/entry/chunking_data_why_it_matters) blog post to learn what chunks are and how they affect performance.

For convenience and manageability the TraCE files are split into 100-years segments.
However, LPJ-GUESS is currently (v.4.0) not capable of reading multiple contiguous NetCDF files in sequence.
They can be concatenated to full length afterwards.

Here is an overview of the procedure:

```ditaa
  +---------+    +----------------+  +-------------+
  |CRU files|    |TraCE–21ka files|  |CRU–JRA files|
  +---------+    +----------------+  +-------------+
       |               |                    |
       v               v                    v
    /----\          /----\               /-----\
    |Crop|          |Crop|               |Unzip|
    \----/          \----/               \-----/
       |               |                    |
       |               v                    v
       |            /-----\              /----\
       |            |Split|              |Crop|
       |            \-----/              \----/
       |               |                    |
       |               v                    v
       |           /-------\           /---------\
       |    +------|Rescale|           |Calculate|
       |    |      \-------/           |Prec. SD |
       v    v          |               \---------/
/--------------\       |                    |
|Calculate Bias|       |                    |
\--------------/       v                    |
       |           /------\                 |
       \---------->|Debias|                 |
                   \------/                 |
                       |                    |
                       v                    |
                 /------------\             |
                 |Add Wet Days|<------------+
                 \------------/
                       |
                       v
                 /------------\
                 |Set Metadata|
                 \------------/
                       |
                       v
                  /--------\
                  |Compress|
                  | Chunk  |
                  |(Concat)|
                  \--------/
```

### Wet Days

### Time Unit

The default unit of the `time` axis in the TraCE-21ka files is “kaBP” (cal. years before present, i.e. before 1950).
That is not standard and cannot be parsed by NCO, CDO, and XArray.

Luckily, TraCE files contain a function `date()`, which converts kaBP to an absolute date with 22 kaBP (the beginning of the TraCE simulation) as the reference time.
A year of, say, 100 thus corresponds to 21,900 years BP.
The `date()` function is used to overwrite the original `time` dimension.

Subsequently, the `time` dimension is converted to a relative format ("months since 1-1-15") so that a CDO commands work properly.

Finally, the unit is converted to "days since 1-1-15" because LPJ-GUESS cannot parse "months" as time steps.

### Limitations

- Paleo-coastlines are currently not taken into account. The resulting valid grid cells cover only the land area from the CRU dataset.

- The time range of the output does not match exactly the years specified in `options.yaml`, but is aligned with the time ranges of the original TraCE files (usually 400-years steps).
If you need finer control, you can run the output file through CDO or NCO. To select for instance the years 56 to 100 (i.e. 21944 to 21900 years BP) run `cdo selyear,56/100 in.nc out.nc`.

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

  - Then you can run the actual script: `make run`. If you encounter problems or need to interrupt (`Ctrl+C`) the script, you can simply restart it again.
  But if you change something in `options.yaml`, you probably have to run `make clean` to start from scratch again!

  - When you are done, you can delete the environment with `make delete_environment` and clean up the files with `make clean`.

### Running LPJ-GUESS

You will need the CRU soil code file for the CF input module of LPJ-GUESS. Adjust the path to it in the generated LPJ-GUESS instruction file.

In order for the CF input module to find soil codes for locations that are not in the CRU file (because those places are now inundated), increase the constant value for the variable `searchradius` (in degrees) in `modules/cfinput.cpp`. Recompile guess afterwards.

Run LPJ-GUESS with the CF input module: `guess -input cf "/path/to/my/instruction_file.ins"`

This is a template for an LPJ-GUESS instruction file: 

```
param "file_gridlist_cf" (str "/data/gridlist.txt")

! This file is used to obtain soil codes.
param "file_cru"     (str "/lpj_guess/data/env/soils_lpj.dat")

! Leave empty to use pre-industrial N deposition rate.
param "file_ndep"     (str "")

param "file_co2"     (str "/data/co2.txt")

param "file_temp"     (str "/data/trace_TREFHT.nc")
param "variable_temp" (str "TREFHT")

param "file_insol"      (str "/data/trace_FSDS.nc")
param "variable_insol" (str "FSDS")

param "file_prec"     (str "/data/trace_PRECT.nc")
param "variable_prec" (str "PRECT")

param "file_wetdays"     (str "/data/trace_WET.nc")
param "variable_wetdays" (str "wet")

! The following parameters need to be declared, but left empty.
param "file_min_temp"      (str "")
param "variable_min_temp"  (str "min_temp")
param "file_max_temp"      (str "")
param "variable_max_temp"  (str "max_temp")
```

Project Outline
---------------

- [x] Fix the broken time dimension! It’s all set to zero.
- [x] Calculate monthly bias for all grid cells against modern CRUNCEP.
- [x] Calculate `PRECT` as `PRECC + PRECL`.
- [x] Crop TraCE data to specified region.
- [x] Split dataset into 100 years files.
- [x] Downscale TraCE dataset to 0.5° grid resolution.
- [ ] Mask oceans and glaciers, based on ICE-5G?
- [ ] How to handle changing coast lines?
- [x] Bias-correct all files.
- [x] Calculate wet days, based on modern monthly wet days. Store them as `wet_days` variable in precipitation file.
- [x] Set standard names for all NetCDF variables.
- [ ] Use land IDs instead of lon/lat for LPJ-GUESS (for performance).
- [x] Compress output files.
- [x] Provide example LPJ-GUESS instruction file.
- [ ] Switch to more recent CRU 4.02?
- [x] Create CO₂ file.
- [x] Create grid list file.
- [x] How to use the many small NetCDF files in LPJ-GUESS in a transient simulation?
- [ ] Crop time

Design Questions
----------------

- Use land IDs or not? How much faster will LPJ-GUESS run? Land IDs have the disadvantage that you cannot easily plot the data file with standard NetCDF tools.

- How are wet days calculated exactly? ⇒ Lookup in publication.

- How to bias-correct radiation?
    + The radiation of TraCE-21ka shouldn’t be biased in any way because it is astronomically calculated.
    + Perhaps we need to bias-correct the cloud cover.

- Is it good to bias-correct precipitation with a simple quotient? ⇒ Compare Lorenz et al. (2016)

Similar Projects
----------------

[Lorenz et al. 2016](https://www.nature.com/articles/sdata201648) for North America:
<https://github.com/fitzLab-AL/climateSims21kto2100>

[Werner et al. 2018](https://www.earth-surf-dynam.net/6/829/2018/) for Chile.

Authors
-------

Main author: [Wolfgang Traylor](mailto:wolfgang.pappa@senckenberg.de), Senckenberg Biodiversity and Climate Research Institute, Frankfurt (BiK-F), Germany

Thanks to Christian Werner and Johan Liakka for their example script.
Thanks to Matthew Forrest for a few tips.

License
-------

[MIT](LICENSE)
