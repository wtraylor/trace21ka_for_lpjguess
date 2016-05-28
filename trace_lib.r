################################################################################
#' R routines to read the netCDF files from the TraCE-21k simulations.
#' 
#' Data from \url{https://www.earthsystemgrid.org/dataset/ucar.cgd.ccsm3.trace.html}
#' Fully-coupled, non-accelerated atmosphere-ocean-sea ice-land surface simulation at the T31_gx3 resolution. The simulation starts at 22,000 years before present (22 ka) and finishes in 1990 CE.
#' @author Wolfgang Pappa
#' @date 2016-05-09
################################################################################

#' Read data from an original TraCE-21k file into a RasterLayer object
#' 
#' If month is specified it is assumed to be monthly data, otherwise not.
#' 
#' @param year The year BP as positive value. (omit to use the first time record)
#' @param month The month [1:12] of the selected year (optional).
#' @param var Variable name (e.g. TREFHT)
#' @param ext An object compatible to the extent() function of the raster
#' 			  package, defining longitude and latitude of the selected
#' 			  region (-90°–+90°N; 0°–360°E). Optional.
#' @param filename Filename of TraCE file containing the given point in time
#' @return A RasterLayer object (5° resolution)
read_trace_raster <- function(
	year,
	month=1,
	var,
	ext,
	filename
){
	is_monthly <- !missing(month)
	## Check parameters
	if (!missing(year) && !is.numeric(year))
		stop("year must be numeric.")
	if (!missing(month)) {
		if (!is.numeric(month))
			stop("month must be numeric.")
		if (!((month >= 1) && (month <= 12)))
			stop("month must be a value in range [1:12].")
	}
	if (missing(var))
		stop("var needs to be specified")

	require(ncdf4) # reading netcdf files
	require(rgdal) # set projection of map
	require(raster) 
	
	if (!file.exists(filename))
		stop(paste0(
			"File \"", filename,"\" ",
			"does not exist. Check if you need to download it from ",
			"https://www.earthsystemgrid.org/dataset/ucar.cgd.ccsm3.trace.html")
		)
	else
		print(paste0("Opening TraCE file »", filename,"«"))
	
	## Open the file
	nc <- nc_open(filename)
	
	time_min <- min(nc$dim$time$vals)
	time_max <- max(nc$dim$time$vals)
	print(paste("Time range of dataset:", time_min,"–",time_max, nc$dim$time$unit))
	
	if (!missing(year)) {
		## In the netCDF files time is in negative ka BP and the month a fraction
		time <- -(year + (month-1)/12)/1000
		## Check if time is in range of the dataset
		if (!((time >= time_min) && (time <= time_max)))
			stop(paste(
				"Chosen time (",time,") is not in range of the dataset (",
				time_max,':',time_min,").", sep="")
			)
		
		## Find the data index for the chosen time: first index after chosen year
		time_index <- which(nc$dim$time$vals >= time)[1]
	} else {
		time_index <- 1 # use first entry
	}
	
	
	print(paste("Record index for time is", time_index))
	print(
		paste(
			"Extent of file:",
			"longitude:",min(nc$dim$lon$vals),"–",max(nc$dim$lon$vals),
			"latitude:",min(nc$dim$lat$vals),"–",max(nc$dim$lat$vals)
	))
	
	## Set up data range to read
	## First two dimensions are longitude (lon) and latitude (lat) 
	## 	-> read the whole world (neg. count)
	## Last dimension is time. From other dimensions first index is used.
	ndims <- nc$var[[var]]$ndims
	start <- c(1, 1, rep(1, ndims-3), time_index)
	count  <- rep(1, ndims-3)
	count[1] <- -1 # whole longitude
	count[2] <- -1 # whole latitude
	count[ndims] <- 1 # only one point in time
	
	## Read all the values (matrix object) and convert them to a RasterLayer object
	raster_obj <- raster( 
		ncvar_get( 
			nc=nc, 
			varid=var, 
			start=start, 
			count=count) 
	)
	
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
	names(raster_obj) <- paste(
		nc$var[[var]]$longname, 
		"in", 
		nc$dim$time$vals[time_index],
		nc$dim$time$unit
	)
	
	## Close the file
	nc_close(nc)
	
	## Crop to selected region
	if (!missing(ext))
		raster_obj <- crop(raster_obj, ext)
	return(raster_obj)
}


#' Read the NetCDF file that has been converted to LPJ-Guess input
read_trace_lpj_raster <- function(
	var,
	filename
){
	require(ncdf4) # reading netcdf files
	require(rgdal) # set projection of map
	require(raster) 
	
	if (!file.exists(filename))
		stop(paste0( "File \"", filename,"\" ", "does not exist. ") )
	else
		print(paste0("Opening file »", filename,"«"))
	
	## Open the file
	nc <- nc_open(filename)
	
	time_min <- min(nc$dim$time$vals)
	time_max <- max(nc$dim$time$vals)
	print(paste("Time range of dataset:", time_min,"–",time_max, nc$dim$time$unit))
	

	time_index <- 1 # use first entry	
	
	print(paste("Record index for time is", time_index))
	print(
		paste(
			"Extent of file:",
			"longitude:",min(nc$dim$lon$vals),"–",max(nc$dim$lon$vals),
			"latitude:",min(nc$dim$lat$vals),"–",max(nc$dim$lat$vals)
	))
	
	## Set up data range to read
	## First two dimensions are longitude (lon) and latitude (lat) 
	## 	-> read the whole world (neg. count)
	## Last dimension is time. From other dimensions first index is used.
	ndims <- nc$var[[var]]$ndims
	start <- c(1, 1, rep(1, ndims-3), time_index)
	count  <- rep(1, ndims-3)
	count[1] <- -1 # whole longitude
	count[2] <- -1 # whole latitude
	count[ndims] <- 1 # only one point in time
	
	## Read all the values (matrix object) and convert them to a RasterLayer object
	raster_obj <- raster( 
		ncvar_get( 
			nc=nc, 
			varid=var, 
			start=start, 
			count=count) 
	)
	
	## For some reason the raster needs to be transposed in order to be plotted correctly
	raster_obj <- raster::t(raster_obj)
	raster_obj <- raster::flip(raster_obj, direction='y')
	
	## Set the projection of the RasterLayer object
	# CRS is the projection class taking a PROJ.4 code
	# +lon_wrap=180 means wrap longitudes in the range 0 to 360.
	crs(raster_obj) <- CRS("+proj=longlat +datum=WGS84 +lon_wrap=180")
	
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
	names(raster_obj) <- paste( nc$var[[var]]$longname )
	
	## Close the file
	nc_close(nc)
	
	## Crop to selected region
	return(raster_obj)
}

#' Convert the CMIP precipitation flux unit m/s to mm/day.
#' 
#' \url{https://bb.cgd.ucar.edu/precipitation-units}:
#' The CMIP5 standard for precipitation is kg m-2 s-1, i.e., a mass flux per 
#' unit area per unit time.The standard CAM units for precipitation are m s-1; 
#' multiply m/s with 1000 kg/m³
prec_flux_to_mm_per_day <- function(x){
	return(x * 1000 * 24 * 3600)
}

#' Convert "days since -20050-1-1 0:0:0" to calendar years (relative to AD)
trace_days_to_calendar_year <- function(x){
	trace_start_calendar_year <- -20050
	return( trunc(x/365.0 + trace_start_calendar_year))
}
