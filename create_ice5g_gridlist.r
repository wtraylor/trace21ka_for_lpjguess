
################################################################################
## CREATE A GRIDCELL LIST FOR LPJ-GUESS FROM ICE5G DATASET
## author: Wolfgang Pappa, May 2016
## 
## Gridlist textfile contains the lon and lat indices (rlon, rlat) and a 
## description (the actual longitude and latitude)
################################################################################

## READ ENVIRONMENT VARIABLES 

## The netCDF file used as input for LPJ, used to read the coordinates from
reference_nc_filename <- Sys.getenv("GRIDLIST_REFERENCE_FILE")
## text file for output, will be overwritten
output_filename <- Sys.getenv("LPJ_FILE_GRIDLIST")
## directory with ice5g files
dir_ice5g <- Sys.getenv("ICE5G_DIR")
## year BP, The point in time for which the land (and glacier) mask is loaded
year <- as.numeric(Sys.getenv("ICE5G_MASK_YEAR"))
## boolean
mask_glaciers <- Sys.getenv("ICE5G_MASK_GLACIERS")=="TRUE"
## boolean
mask_ocean <- Sys.getenv("ICE5G_MASK_OCEANS")=="TRUE"


require (ncdf4) # reading netcdf files

if (mask_ocean || mask_glaciers){
	source(file.path(Sys.getenv("SCRIPT_DIR"), "ice5g_lib.r"))
}

## Name of the output gridcell file
if (file.exists(output_filename)) {
	write(paste("removing existing gridlist file:", output_filename), stdout())
	file.remove(output_filename)
}

## Raster object with gridcells
# use first entry of time, we are only interested in the matrix of gc
nc <- nc_open(reference_nc_filename)

## read the ice5g data 
if (mask_ocean){
	landmask <- read_ice5g_landmask( year=year, dir=dir_ice5g)
}
if (mask_glaciers){
	glaciermask <- read_ice5g_glaciermask( year=year, dir=dir_ice5g)
}

for (rlon in 1:length(nc$dim$lon$vals)){
	for (rlat in 1:length(nc$dim$lat$vals)) {
		lon <- nc$dim$lon$vals[rlon]
		lat <- nc$dim$lat$vals[rlat]
		exclude_cell <- FALSE
		## exclude the gridcell if it’s on water
		if (mask_ocean){
			exclude_cell <- exclude_cell || is.na(
				raster::extract(landmask, cellFromXY(landmask, c(lon,lat)))
			)
		}
		## exclude the gridcell if it’s glaciated
		if (mask_glaciers){
			exclude_cell <- exclude_cell || is.na(
				raster::extract(glaciermask, cellFromXY(glaciermask, c(lon,lat)))
			)
		}
		if (!exclude_cell) {
			cat(
				paste(
					rlon-1, # longitude index (starting with zero)
					rlat-1, # latitudo index (starting with zero)
					paste0( # description
						paste(round(lon,3),nc$dim$lon$units),
						",",
						paste(round(lat,3),nc$dim$lat$units)
					), 
					sep='\t'
				),
				file=output_filename,
				append=TRUE,
				sep="\n"
			)
		}
	}
}

nc_close(nc)

