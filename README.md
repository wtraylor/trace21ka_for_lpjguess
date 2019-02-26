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

### Precipitation

The TraCE-21ka dataset provides two precipitation variables from the atmosphere submodel `CAM` from the CCSM3 model:

- `PRECC`: Convective precipitation rate (liquid + ice)
- `PRECL`: Large-scale (stable) precipitation rate (liquid + ice)

We are interested in the _total_ precipitation `PRECT`, which is the sum of `PRECC` and `PRECL`.
`PRECT` is automatically calculated in this script.

The TraCE-21ka precipitation files come with the precipitation unit m/s.
This is the water flux of the CAM model.

LPJ-GUESS expects the precipitation unit kg/m²/s (standard name `precipitation_flux`).
We convert from m/s to kg/m²/s dividing by 1000, since water has a density of $`\rho = 1 kg/l = 1000 kg/m^3`$:

```math
1 \frac{kg}{s*m^2}
= \frac{1000}{1000} \frac{m*kg}{s*m^3}
= 10^{-3} \frac{m}{s} * \rho
```

Compare also this forum thread: <https://bb.cgd.ucar.edu/precipitation-units>

The CRU-TS dataset comes with precipiation in mm/month. It converts as follows ($`d`$ is the number of days in the month):

```math
1 \frac{kg}{s*m^2}
= \rho^{-1} \frac{m}{s}
= \frac{1}{\rho * d*24*60*60} \frac{mm}{month}
= \frac{1}{1000 * d*24*60*60} \frac{mm}{month}
```

### Wet Days

Wet days are calculated following [Werner et al. 2018](https://www.earth-surf-dynam.net/6/829/2018/) (Appendix A).

The daily precipitation in a month is described with a [gamma distribution](https://en.wikipedia.org/wiki/Gamma_distribution) (Γ) with the parameters *shape* (α) and *rate* (β).
See [Geng et al. 1986](http://www.sciencedirect.com/science/article/pii/0168192386900146) for how gamma distributions are used to describe precipitation amounts.

Be $`x_{mean}`$ the mean precipitation (mm/day) of the month in question.
Be $`x_{std}`$ the standard deviation of daily precipitation amount in the month.

```math
\alpha = (x_{mean} / x_{std})^2
\beta = x_{std}^2 / x_{mean}
```

$`x_{mean}`$ is given for each month and grid cell by the bias-corrected precipitation of the TraCE-21ka dataset.
Precipitation flux (kg/m²/s) was converted to amount (mm/month) as described in Section “Precipitation” above.

$`x_{std}`$ is not given by the TraCE-21ka data.
Therefore it is assumed to be constant over time and derived from the modern daily precipitation in the CRU-JRA dataset.
From the CRU-JRA dataset only the years from 1958 to 1990 are used because TraCE-21ka only covers the time until 1990 CE.

```math
F(x \alpha \beta) = \frac{1}{\beta^\alpha \Gamma(\alpha)} \int_0^x t^{\alpha-1} \exp(-t/b) dt
```

F is the probability that an observation will fall in the interval [0,x].
In our case, the observation is the amount of rain in a day in mm.

In order to derive the number of wet days ($`n_{wet}`$), a threshold value $`x_t`$ in mm/day needs to be defined: a day with at least this amount of precipitation is called a “wet day”.
The threshold value can be defined in `options.yaml` under `precip_threshold`.

The probability $`F(x_t \alpha \beta)`$ tells us how likely it is that any given day in the month is “dry”.
The following term gives us the the _wet_ days in a month of $`n_{day}`$ days:

```math
n_{wet} = n_{day} (1 - F(x_t \alpha \beta))
```

### Time Unit

The default unit of the `time` axis in the TraCE-21ka files is “kaBP” (cal. years before present, i.e. before 1950).
That is not standard and cannot be parsed by NCO, CDO, and XArray.

Luckily, TraCE files contain a function `date()`, which converts kaBP to an absolute date with 22 kaBP (the beginning of the TraCE simulation) as the reference time.
A year of, say, 100 thus corresponds to 21,900 years BP.
The `date()` function is used to overwrite the original `time` dimension.

Subsequently, the `time` dimension is converted to a relative format ("months since 1-1-15") so that a CDO commands work properly.

Finally, the unit is converted to "days since 1-1-15" because LPJ-GUESS cannot parse "months" as time steps.

### Bias Calculations

Bias is calculated for each individual grid cell in the final resolution and for each month of the year.
The modern TraCE values in 1900–1990 CE are aggregated to 12 values with the monthly means over the time period in the study area.
The same is done with the CRU data.

Be $`t`$ the value for one month and one grid cell in the aggregated modern TraCE data.
Be $`c`$ the corresponding value from the CRU dataset.
The goal is to derive the debiased value $`x'`$ for each (biased) value $`x`$ in the regridded TraCE dataset.
As an intermediary step, a bias map is created with values $`b`$ for all grid cells and all (12) months.

For modern times, $`x'`$ will be very close to the corresponding $`c`$ value.

#### Temperature
For temperature, the CRU value $`c`$ is first converted from degrees Celsius to Kelvin.

```math
b = t - c
x' = x - b
```

#### Precipitation
For precipitation, the CRU value is first converted from mm/month to a flux in kg/m²/s.

```math
b = t / c
x' = x / b
```

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

To be defined
