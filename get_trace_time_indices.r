#! Rscript
## Simple R script to find out the time indices (start, beginning with 0, and end) for a 
## given time frame in the records of a TraCE-21ka file
# Wolfgang Pappa, May 2016
library(ncdf4)



## Read command line arguments 
args <- commandArgs(trailingOnly = TRUE)

filename <- args[1]
firstyear <- as.numeric(args[2])  # pos. year BP
lastyear <- as.numeric(args[3]) # pos. year BP


nc <- nc_open(filename)

begin <- -firstyear/1000 # neg. ka BP
end <- -lastyear/1000 # neg. ka BP
time <- nc$dim$time$vals

# write(paste0("file time range: ",min(time)," - ",max(time)), stderr())
if ((max(time) >= begin) && (min(time) <= end)) 
{
	time_start <- min(which(nc$dim$time$vals >= begin))
		
	time_stop <- max(which(nc$dim$time$vals <= end))
# 	write(paste0("start=",time_start," count=",time_count," - total count=", length(time)), stderr())

	## print result
	write(paste(time_start+1, time_stop+1), stdout())
}
## no output if out of range

nc_close(nc)
