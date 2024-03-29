<!--
SPDX-FileCopyrightText: 2021 Wolfgang Traylor <wolfgang.traylor@senckenberg.de>

SPDX-License-Identifier: CC-BY-4.0
-->

Prepare TraCE-21ka monthly data as LPJ-GUESS drivers
====================================================

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5060114.svg)](https://doi.org/10.5281/zenodo.5060114)

Motivation
----------

We want to use the transient monthly paleoclimate dataset [TraCE-21ka](http://www.cgd.ucar.edu/ccr/TraCE/) as climatic driving data for the DGVM [LPJ-GUESS](http://iis4.nateko.lu.se/lpj-guess/).

Bias-correction is necessary because present-day temperature and precipitation of the CCSM3 simulations diverge tremendously from measurements in some regions (e.g. NE-Siberia).
We want to downscale the data together with bias-correcting it because this way orographic effects are represented (e.g. higher altitudes are colder).

Description
-----------

This script bundle **downscales** and **bias-corrects** the monthly TraCE-21ka paleoclimate dataset ([He 2011](http://www.aos.wisc.edu/uwaosjournal/Volume15/He_PhD_Thesis.pdf)) and prepares NetCDF files that are readable as driving data by LPJ-GUESS.

Bias-correction of temperature and precipitation is based on the CRU dataset of modern monthly climate between 1900 and 1990 in 0.5° by 0.5° grid cell resolution.<!--TODO: Citation-->

The TraCE files are regridded to match the CRU resolution using bilinear interpolation.
Note that the higher resolution in of itself does not provide any gain in information.
It only helps to create orographic/altitudinal effects.

The **chunking** of the output NetCDF files is optimized for LPJ-GUESS input, i.e. for reading each grid cell separately for the whole time series.
See [this](https://www.unidata.ucar.edu/blogs/developer/entry/chunking_data_why_it_matters) blog post to learn what chunks are and how they affect performance.

For convenience and manageability the TraCE files are split into 100-years segments.
However, LPJ-GUESS is currently (v.4.0) not capable of reading multiple contiguous NetCDF files in sequence.
They can be concatenated to full length afterwards.

![Overview of file processing to create downscaled and debiased TraCE-21ka files for LPJ-GUESS.](figures/process_overview.png)
<!--
The image "figures/process_overview.png" was created with ditaa from "figures/process_overview.ditaa".
http://ditaa.sourceforge.net/
-->

### Precipitation

The TraCE-21ka dataset provides two precipitation variables from the atmosphere submodel `CAM` from the CCSM3 model:

- `PRECC`: Convective precipitation rate (liquid + ice)
- `PRECL`: Large-scale (stable) precipitation rate (liquid + ice)

We are interested in the _total_ precipitation `PRECT`, which is the sum of `PRECC` and `PRECL`.
`PRECT` is automatically calculated in this script.

The TraCE-21ka precipitation files come with the precipitation unit m/s.
This is the water flux of the CAM model.

LPJ-GUESS expects the precipitation unit kg/m²/s (standard name `precipitation_flux`).
1 kg/m² precipitation _amount_ is equivalent to 1 mm water _column._
We can simply convert from m/s to mm/s, which is then equivalent to kg/m²/s.
<!-- I don’t know the mathematical symbol for this kind of equivalency (amount = column height). So I just use an equal sign. -->

```math
1 \frac{kg}{s*m^2}
= 1 \frac{l}{s*m^2}
= 1 \frac{mm}{s}
= 10^{-3} \frac{m}{s}
```

Compare also this forum thread: <https://bb.cgd.ucar.edu/precipitation-units>

The CRU-TS dataset comes with precipiation in mm/month.
So in order to convert mm/month to kg/m²/s (equivalent to mm/s, see above), we need to divide by the number of seconds in a month:

```math
1 \frac{kg}{s*m^2}
= \frac{1}{d*24*60*60} \frac{mm}{month}
```

$`d`$ is the number of days in the month.

### Wet Days

Wet days are calculated following [Werner et al. 2018](https://www.earth-surf-dynam.net/6/829/2018/) (Appendix A).

The daily precipitation in a month is described with a [gamma distribution](https://en.wikipedia.org/wiki/Gamma_distribution) (Γ) with the parameters *shape* (α) and *rate* (β).
See [Geng et al. 1986](http://www.sciencedirect.com/science/article/pii/0168192386900146) for how gamma distributions are used to describe precipitation amounts.

Be $`x_{mean}`$ the mean precipitation (mm/day) of the month in question.
Be $`x_{std}`$ the standard deviation of daily precipitation amount in the month.

```math
\alpha = (x_{mean} / x_{std})^2 \\
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
b = t - c \\
x' = x - b
```

#### Precipitation
For precipitation, the CRU value is first converted from mm/month to a flux in kg/m²/s.

```math
b = t / c \\
x' = x / b
```

#### Cloud Cover
For calculating the solar radiation we need to debias the total cloud cover `CLDTOT` (vertically-integrated total cloud fraction).
`CLDTOT` is equivalent to the `cld` variable in the CRU dataset.

Cloud cover is fractional and falls between 0 and 1.
In order to preserve this 0 to 1 range, we follow the approach of [Lorenz et al (2016)](https://www.nature.com/articles/sdata201648) (Section “Shortwave Radiation” on page 5).
The bias $`b`$ is calculated as an exponent.

```math
b = log(t) / log(c)
\\
x' = x^b
```

In case that modern TraCE is not biased at all, $`t`$ (TraCE) will be equal to $`c`$ (CRU).
In this case, $`b = 1`$, which means no change will be done ($`x' = x^1 = x`$).

Now the logarithm of a number between 0 and 1 will always be negative or zero.
The quotient of two negative numbers is positive, so we expect $`b`$ to always be positive.

If modern TraCE is too cloudy ($`t > c`$), $`b`$ will be _less_ than 1 because the absolute value of $`log(t)`$ is smaller than the absolute value of $`log(c)`$ (the negative signs are canceled out).
Then the paleo cloud cover will be _decreased_: $`x' = x^b < x `$

If modern TraCE is biased towards clear sky ($`t < c`$), $`b`$ will be _greater_ than 1, and the paleo cloud cover will be _increased_: $`x' = x^b > x `$

#### Solar Radiation
These are the CCSM3 variables:
- `FSDS`: Downwelling solar flux at surface in W/m².
- `CLDTOT`: Vertically-integrated total cloud fraction. This is equivalent to the `cld` variable in the CRU dataset.
- `FSDSC`: Incoming radiation with a completely clear sky (zero cloud cover).
- `FSDSCL`: Incoming radiation with a completely overcast sky (100% cloud cover). This variable is not available for download from <https://www.earthsystemgrid.org> so we calculate it manually.

In the TraCE simulations, `FSDS` is calculated as the sum of weighted means of `FSDSC` (clear sky) and `FSDSCL` (cloudy sky) surface downwelling shortwave radiation flux, using `CLOUD`.
`FSDSC` is the incoming radiation from space and is not biased.
The fraction `FSDSCL` is biased and needs to be corrected in order to get a good `FSDS` variable.

Reconstruct the original (i.e. biased) `FSDSCL` variable from the original `FSDS` and `CLDTOT`:
```math
FSDS = FSDSC * (1 - CLDTOT) + FSDSCL * CLDTOT
\\
\implies FSDSCL = (FSDS - FSDSC * (1 - CLDTOT)) / CLDTOT
```

Calculate debiased `FSDS`:
```math
FSDS_{debiased} = (1 - CLDTOT_{debiased}) * FSDSC  + CLDTOT_{debiased} * FSDSCL.
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

### External Files
The files in the `external_files` directory are too big to be included in the Git repository.
They reside in the directory `172.30.45.24:/akira_data/wtraylor/trace21ka_for_lpjguess/` on the BiK-F server.<!--TODO: update that path-->
You can download them from the internal network or request access from the authors.
To verify that you have all files and that they are correct, check the MD5 checksums:

1. Open a terminal in the root of the repository, where the `MD5.txt` file lies.
	- You can open the `MD5.txt` file with a text editor to see which files you need and what directory structure is expected.
1. Copy or mount or symlink the big files in the `external_files` subdirectory directly.
	- `external_files` should not exist yet.
	- Mount via SSH: `mkdir external_files ; sshfs -o compression=yes user@ip_address:/path/to/directory external_files`
	- Symlink from local storage: `ln --symbolic /path/to/local/storage external_files`
	- Copy from local or remote (see `man rsync` for more options): `mkdir external_files ; rsync --progress --copy-links --recursive /path/to/storage/* external_files/`
1. Run `md5sum --check MD5.txt` and check the output in the terminal. Are all files there and checked correctly?
1. If some files failed the test, download them again. If that fails, contact the authors.

### Download Data

Important: Do not change the original file names!

- Download the TraCE-21ka monthly datasets for the CCSM3 variables `PRECC`, `PRECL`, `TREFHT`, `CLDTOT`, `FSDS`, and `FSDSC` for your time period from [earthsystemgrid.org](https://www.earthsystemgrid.org/dataset/ucar.cgd.ccsm3.trace.html).

- Download the global monthly CRU TS 4.01 data set in 0.5° resolution as the original zip files from [crudata.uea.ac.uk](https://crudata.uea.ac.uk/cru/data/hrg/cru_ts_4.01/). Save all files with their original name in one directory. You will need the following variables: `cld`, `pre`, `tmp`, `wet`

- Download the CRU JRA-55 precipitation (`pre`) data set from [vesg.ipsl.upmc.fr](https://vesg.ipsl.upmc.fr/thredds/catalog/work/p529viov/crujra/catalog.html). Only the years 1958 to 2017 are used. You can use the download script `make download_crujra` (requires `wget` to be installed).

### Running the script

1) Customize `options.yaml` to your own needs.
Be careful not to keep other files in your "heap" or "output" directory since they will be deleted with `make clean`.

2) Open a terminal in the root of this repository (where the `Makefile` lies).

  - If you don’t have Miniconda or Anaconda installed in your system yet, you can install `miniconda` through your package manager or download it manually (<https://conda.io/miniconda.html>). Alternatively run `make install_conda`, which will download and extract a Miniconda installation for Linux 64-bit into a subdirectory.

  - Run `make create_environment`. This will create a local Conda environment for this little project in the subdirectory `conda_environment` and install all dependencies.

  - Then you can run the actual script: `make run`. If you encounter problems or need to interrupt (`Ctrl+C`) the script, you can simply restart it again.
  But if you change something in `options.yaml`, you probably have to run `make clean` to start from scratch again!

  - Any command output is also written to a file `prepare_trace_for_guess.log`.
  You can look at it with `make log`.

  - When you are done, you can delete the environment with `make delete_environment` and clean up the files with `make clean`.

### Running LPJ-GUESS

You will need the CRU soil code file for the CF input module of LPJ-GUESS. Adjust the path to it in the generated LPJ-GUESS instruction file.

In order for the CF input module to find soil codes for locations that are not in the CRU file (because those places are now inundated), increase the constant value for the variable `searchradius` (in degrees) in `modules/cfinput.cpp`. Recompile guess afterwards.

Run LPJ-GUESS with the CF input module: `guess -input cf "/path/to/my/instruction_file.ins"`

This is a template for an LPJ-GUESS instruction file: 

```
! Don’t use an absolute path in parallel runs here because this refers to the
! gridlist fragment that one single job takes. The total gridlist is split up
! by the `submit.sh` script.
param "file_gridlist_cf" (str "./gridlist.txt")

! This file is used to obtain soil codes. It’s not shipped with LPJ-GUESS, so
! you need to request it from the LPJ-GUESS developers or somewhere else.
param "file_cru"     (str "/path/to/cruncep_1901_2015.bin")

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
param "variable_wetdays" (str "WET")

! The following parameters need to be declared, but left empty.
param "file_min_temp"      (str "")
param "variable_min_temp"  (str "min_temp")
param "file_max_temp"      (str "")
param "variable_max_temp"  (str "max_temp")
```

To Do
-----

- [ ] Render LaTeX math in `README.md` as PNG files for GitHub: <https://quicklatex.com>
- [ ] Mask oceans and glaciers? Perhaps based on ICE-5G?
- [ ] How to handle changing coast lines?
- [ ] Switch to more recent CRU 4.02?
- [ ] Add the script `check_external_files` for more convenience.

### Open Design Questions

- Use land IDs or not? How much faster will LPJ-GUESS run? Land IDs have the disadvantage that you cannot easily plot the data file with standard NetCDF tools.

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

- Thanks to Christian Werner and Johan Liakka for their example script.
- Thanks to Matthew Forrest for a few tips.
- Thanks to Antoine Champreux for testing the scripts along the way.

References
----------

- Geng, Shu, Frits W. T. Penning de Vries, and Iwan Supit. 1986. “A Simple Method for Generating Daily Rainfall Data.” Agricultural and Forest Meteorology 36 (4): 363–76. https://doi.org/https://doi.org/10.1016/0168--1923(86)90014-6.
- He, Feng. 2011. “Simulating Transient Climate Evolution of the Last Deglaciation with CCSM 3.” PhD thesis, University of Wisconsin-Madison.
- Lorenz, David J., Diego Nieto-Lugilde, Jessica L. Blois, Matthew C. Fitzpatrick, and John W. Williams. 2016. “Downscaled and Debiased Climate Simulations for North America from 21,000 Years Ago to 2100ad.” Scientific Data 3 (July). http://dx.doi.org/10.1038/sdata.2016.48.
- Werner, C., M. Schmid, T. A. Ehlers, J. P. Fuentes-Espoz, J. Steinkamp, M. Forrest, J. Liakka, A. Maldonado, and T. Hickler. 2018. “Effect of Changing Vegetation and Precipitation on Denudation – Part 1: Predicted Vegetation Composition and Cover over the Last 21 Thousand Years Along the Coastal Cordillera of Chile.” Earth Surface Dynamics 6 (4): 829–58. https://doi.org/10.5194/esurf-6-829-2018.

License
-------

This project follows the [REUSE][] licensing standard: Every file has its license and copyright holders in the header or in a separate file with a `.license` filename extension.

All scripts are under the [MIT license][], and text and media under [CC-BY][].

License texts can be found in the `LICENSES/` subdirectory inside this repository.

[REUSE]: https://reuse.software
[MIT license]: https://mit-license.org/
[CC-BY]: https://creativecommons.org/licenses/by/4.0/
