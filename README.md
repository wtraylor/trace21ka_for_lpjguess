Prepare TraCE-21ka monthly climate data as input for LPJ-GUESS 
===============================================================

This set of bash and R scripts cuts out a region and time slice of the TraCE-21ka output and creates NetCDF files as well as grid list, CO₂ and instruction (ins) text files that can be used as input for the LPJ-GUESS 3.1 CF input module.
Read the comments in the script files for further details.

Prerequisites
-------------

- Linux bash

- nco: [http://nco.sourceforge.net/]()

- R: [http://r-project.org/]() (with the [https://rstudio.github.io/packrat/](`packrat`) package)

Procedure
---------

- Download the TraCE-21ka monthly datasets for the CCSM3 variables `PRECC`, `PRECL`, `TREFHT`, and `INSOL` for your time period from [earthsystemgrid.org](https://www.earthsystemgrid.org/dataset/ucar.cgd.ccsm3.trace.html).
Only download those files for the time frame that you are actually interested in.
Having more files in the source directory for this script will lead to much extra calculation time because _all_ files will be concatenated before cropping to the selected time frame.

- If you want to create a grid list file without the grid cells on glaciers or ocean, download also the ICE-5G dataset from: [https://pmip2.lsce.ipsl.fr/design/ice5g/]().

- Customize all variables in `trace_settings.sh`. The cropping region and time, and the file paths are relevant.

- Then run `./prepare_trace_for_lpj.sh`.

Note
----

- You will need the CRU soil code file for the CF input module of LPJ-GUESS. Adjust the path to it in the generated LPJ-GUESS instruction file.

- In order for the CF input module to find soil codes for locations that are not in the CRU file (because those places are now inundated), increase the constant value for the variable `searchradius` (in degrees) in `modules/cfinput.cpp`. Recompile guess afterwards.

Starting LPJ-GUESS
------------------

- You can include the generated instruction file directly in your LPJ-GUESS instruction file as `import "/path/to/trace_file.ins"`.

- Run LPJ-GUESS with the CF input module: `guess -input cf "/path/to/my/instruction_file.ins"`
