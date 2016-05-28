################################################################
## TraCE-21ka CO2 VALUES FOR LPJ-GUESS
## See bash script for info on time and calendar
################################################################

source(paste0(Sys.getenv("SCRIPT_DIR"),"trace_lib.r"))

## Convert decimal numbers from TraCE file into ppmv as LPJ-GUESS needs it
to_ppmv <- function(x){
	x*10^6
}


##################################################################
library("ncdf4")

## Load variables as defined by the bash scripts
trace_filename <- Sys.getenv("CO2_REFERENCE_FILE")
co2_filename <- Sys.getenv("LPJ_FILE_CO2")
trace_start_calendar_year <- as.numeric(Sys.getenv("TRACE_START_CALENDAR_YEAR"))

## Remove existing file
if (file.exists(co2_filename)) {
	write(paste("removing existing file", co2_filename), stdout())
	file.remove(co2_filename)
}

nc <- nc_open(trace_filename)

## Load time (as years) and CO2 into a two column dataframe
d <- data.frame(
	trace_days_to_calendar_year(ncvar_get(nc, varid="time")),
	to_ppmv(ncvar_get(nc, varid="co2vmr"))
)
colnames(d) <- c("year","co2")

## Build yearly averages
d <- aggregate(d$co2, by=list(d$year), mean)


## Print dataframe to text file
apply(
	d,
	1, # iterate over rows of the dataframe
	function(x){
		cat(
			paste(x[1],x[2], sep='\t'),
			file=co2_filename,
			append=TRUE,
			sep='\n'
		)
	}
)

nc_close(nc)
