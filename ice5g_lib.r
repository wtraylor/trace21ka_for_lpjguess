################################################################################
#' R routines to read and plot the netCDF files from the ICE-5G simulations.
#' 
#' Data from \url{https://pmip2.lsce.ipsl.fr/design/ice5g/}
#' @author Wolfgang Pappa
#' @date 2016-05-09
#' ICE-5G is a new global ice sheet reconstruction produced by W.R Peltier 
#' of the Department of Physics in the University of Toronto, Canada.
#' The files available here pertain to ICE-5G (VM2) Version 1.2.
#'  the ICE-5G v1.2 data files are only available at a 1x1 degree resolution
################################################################################

require(ncdf4) # reading netcdf files
require(rgdal) # set projection of map
require(raster)

#' Read data from an ICE-5G file into a RasterLayer object
#' 
#' Variables:
#' - "sftgit" thickness of the ice sheet (m)
#' - "sftgif" percent of ice sheet cover of gridcell (%)
#' - "orog" surface altitude (m NN)
#' 
#' @param year Numerical value in years BP (e.g. 20000); in range [0,21000]
#' @param var The variable to read: "orog"|"sftgit"|"sftgif"
#' @param ext An object compatible to the extent() function of the raster
#' 			  package, defining longitude and latitude of the selected
#' 			  region (-90°–+90°N; 0°–360°E). Optional.
#' @param dir Directory of ICE-5G files, with trailing '/'.
#' @return A RasterLayer object (1° resolution)
read_ice5g_raster <- function(
	year=ice5g_mask_year,
	var,
	ext,
	dir=dir_ice5g 
){
	## Check parameters
	if (missing(year))
		stop("year needs to be specified")
	if (!is.numeric(year))
		stop("year must be numeric.")
	if (!((year >= 0) && (year <= 21000)))
		stop("year must be in between 0 and 21000.")
	if (missing(var))
		stop("var needs to be specified")
	if (!((var=="orog") || (var=="sftgit") || (var=="sftgif")))
		stop("var must be \"orog\"|\"sftgit\"|\"sftgif\"")
	
	## round time to available time points: 
	## 21 to 17 ka: 1000 years steps; later 500 years
	time <- year / 1000
	if (time >= 17) {
		# round to the nearest 1.0 step
		time <- round(time)
	} else {
		# round to the nearest 0.5 step:
		time <- time - (time %% 0.5) + 0.5*round(2*(time %% 0.5))
	}
	## Open the file
	filename <- file.path(dir,
                        paste0("ice5g_v1.2_", sprintf("%04.1f", time), "k_1deg.nc"))
  if (!file.exists(filename)){
    print("ICE-5G file does not exist: ", filename)
    stop()
  }
	nc <- nc_open(filename)
	
	
	## Read all the values (matrix object) and convert them to a RasterLayer object
	raster_obj <- raster( ncvar_get( nc, var) )
	
	## Set the projection of the RasterLayer object
	# CRS is the projection class taking a PROJ.4 code
	# +lon_wrap=180 means wrap longitudes in the range 0 to 360.
	crs(raster_obj) <- CRS("+proj=longlat +datum=WGS84 +lon_wrap=180")
	
	## For some reason the raster needs to be transposed in order to be plotted correctly
	raster_obj <- raster::t(raster_obj)
	raster_obj <- raster::flip(raster_obj, direction='y')
	
	## Set the extent of the RasterLayer object to fit the netCDF data
	xres <- nc$dim$lon$vals[2] - nc$dim$lon$vals[1]
	yres <- nc$dim$lat$vals[2] - nc$dim$lat$vals[1]
	raster::extent(raster_obj) <- raster::extent(
		min(nc$dim$lon$vals),
		max(nc$dim$lon$vals) + xres, # add the dimension of the last gridcell
		min(nc$dim$lat$vals),
		max(nc$dim$lat$vals) + yres # add the dimension of the last gridcell
	)
	
	## Set metadata
	names(raster_obj) <- nc$var[[var]]$longname
	
	## Close the file
	nc_close(nc)
	
	## Crop to selected region
	if (!missing(ext))
		raster_obj <- crop(raster_obj, ext)
	return(raster_obj)
}

#' Get RasterLayer object with 1 for land and NA for sea
#' See documentation for read_ice5g_raster
read_ice5g_oceanmask <- function(...){
	r <- read_ice5g_raster(var="orog", ...)
	fun <- function(x) { 
		x[x>0] <- 1
		x[x<=0] <- NA
		return(x) 
	}
	r <- calc(r, fun)
	return (r)
}

#' Get RasterLayer object with NA for land and 1 for sea
#' See documentation for read_ice5g_raster
read_ice5g_landmask <- function(...){
	r <- read_ice5g_raster(var="orog", ...)
	fun <- function(x) { 
		x[x>0] <- NA
		x[x<=0] <- 1
		return(x) 
	}
	r <- calc(r, fun)
	return (r)
}

#' Get contour object of paleo-coastlines
#' See documentation for read_ice5g_raster and read_ice5g_landmask
#' Parameters are passed on to read_ice5g_landmask
read_ice5g_coastlines <- function(...
){
	r <- read_ice5g_raster(var="orog", ...)
	r <- calc(r, function(x){x > 0}) # 1 for sea, 0 for land
	r <- rasterToContour(r, nlevels=1)
	return (r)
}

#' Get RasterLayer object with 1 for glaciated and NA for non-glaciated
#' See documentation for read_ice5g_raster
read_ice5g_glaciermask <- function( ... ){
	r <- read_ice5g_raster(var="sftgif", ...)
	fun <- function(x) { 
		x[x>0] <- 1
		x[x<=0] <- NA
		return(x) 
	}
	r <- calc(r, fun)
	return (r)
}

#' Get a RasterBricks object with layers for ocean and glaciers from ICE-5G dataset.
#' 
#' The center of each gridcell of input raster map will be checked against
#' the ICE-5G data.
#' @param r The raster map to mask. Gridcells of the returned
#' raster object will match this. If NULL, no rescaling happens.
#' @param ... Passed on to read_ice5g_raster
#' @return RasterBricks object with layers "ocean" and "glacier" with values 1
#' for water/glaciers and NA for none.
read_ice5g_mask <- function( r=NULL, ...
){
	## read the raster 
	landmask <- read_ice5g_landmask( ... )
	glaciermask <- read_ice5g_glaciermask( ... )
	
	
	if (!is.null(r)) {
		ice5g_raster <- raster::brick(list(landmask,glaciermask))
	}else {
		ice5g_raster <- raster::brick(list(r,r))
		for (i in 1:raster::ncell(ice5g_raster)){
			coords <- raster::xyFromCell(ice5g_raster, i)
			ice5g_raster[["ocean"]][i] <- ifelse(
				is.na( raster::extract(landmask, raster::cellFromXY(landmask, coords))),
				NA, #is land
				1 #is ocean
			)
			ice5g_raster[["glacier"]][i] <- ifelse(
				is.na( raster::extract(glaciermask, raster::cellFromXY(glaciermask, coords))),
				NA, # unglaciated
				1 #is glacier
			)
		}
	} 
	names(ice5g_raster) <- c("ocean", "glacier")
	return(ice5g_raster)
}
