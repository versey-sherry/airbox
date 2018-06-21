library(ncdf4)
library(raster)
library(rgdal)
library(ggplot2)

setwd("/Users/sherry/Desktop/taiwan_airpollution/airbox/")
ncfile <- list.files(pattern = "*.nc4")
#airbox_processed <- read.csv("airbox_processed.csv", stringsAsFactors = FALSE)
#airbox_processed <- airbox_processed[order(airbox_processed$unix_time), ]
time_loc <- airbox_processed[c("Date", "lon", "lat")]
time_loc$month <- as.numeric(format.Date(as.Date(time_loc$Date), "%m"))

#check the meata data of NC file.
nc_data <- nc_open(ncfile[1])
{
  sink("nc_meta.txt")
  print(nc_data)
  sink()
}
nc_close(nc_data)
#loop through the file and find the wind speed.
u_wind <- c()
v_wind <- c()
a = 1
for (a in 1:length(ncfile)){
  nc_data <- nc_open(ncfile[a])
  temp <- time_loc[time_loc$month == a,  c("lon", "lat")]
  temp <- SpatialPoints(temp)
  lon <- ncvar_get(nc_data, "lon")
  lat <- ncvar_get(nc_data, "lat")
  u50m <- ncvar_get(nc_data, "U50M")
  v50m <- ncvar_get(nc_data, "V50M")
  nc_close(nc_data)
  #raster value is lat, lon, so transpose is needed
  r_u <- raster(t(u50m), xmn=min(lon), xmx=max(lon), ymn=min(lat), 
                ymx=max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
  r_v <- raster(t(v50m), xmn=min(lon), xmx=max(lon), ymn=min(lat), 
                ymx=max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
  u_wind <- c(u_wind, extract(r_u, temp))
  v_wind <- c(v_wind, extract(r_v, temp))
}

#length(u_wind) == nrow(airbox_processed)
#length(v_wind) == nrow(airbox_processed)
ag_wind <- sqrt(u_wind^2+v_wind^2)
time_loc$uwind <- u_wind
time_loc$vwind <- v_wind
time_loc$agwind <- ag_wind

airbox_processed$agwind <- ag_wind
names(airbox_processed)

p1 <- hist(ag_wind)
p1$counts <- p1$density
plot(p1, main = "Histogram of Aggregated Wind Speed", xlab = "Aggregated Wind Speed (m/s)")

write.csv(time_loc, "loc_windspeed.csv")
