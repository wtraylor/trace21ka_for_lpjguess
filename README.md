Prepare TraCE-21ka monthly climate data as input for LPJ-GUESS 
==============================================

This set of bash and R scripts cuts out a region and time slice of the TraCE-21ka output and creates NetCDF files as well as gridlist, CO₂ and instruction (ins) text files that can be used as input for the LPJ-GUESS 3.1 CF input module.
Read the comments in the script files for further details.

Procedure:
----------------
- Make sure you have all necessary software installed: 
	- bash
	- nco: http://nco.sourceforge.net/
	- R: http://r-project.org/ (with packages ncdf4, raster, rgdal)
- Download the TraCE-21ka monthly datasets for the CCSM3 variables PRECC, PRECL, TREFHT, and INSOL for your time period from https://www.earthsystemgrid.org/dataset/ucar.cgd.ccsm3.trace.html
- If you want to create a gridlist file without the gridcells on glaciers or ocean, download also the ICE-5G dataset from: https://pmip2.lsce.ipsl.fr/design/ice5g/
- Customize all variables in trace_settings.sh
- Make sure you have those environment variables available in your bash session by executing ». ./trace_settings.sh« or executing it on login by adding trace_settings.sh in ~/.profile
- Then run »./prepare_trace_for_lpj.sh«

Note
------------
In order for the CF input module to find soil codes for locations that are not in the CRU file (because those places are now inundated), increase the constant value for the variable ›searchradius‹ (in degrees) in modules/cfinput.cpp. Recompile guess afterwards.
