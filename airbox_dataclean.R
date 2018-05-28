library(geosphere)
library(raster)
library(sp)
library(rgdal)
library(maptools)
library(maps)
library(ggmap)

setwd("/Users/sherry/Desktop/taiwan_airpollution/airbox")

copytable <- function(table){
  clip <- pipe("pbcopy", "w")
  write.table(table, sep = "，", file = clip)
  close(clip)
}

avg_diff <- function(list){
  list <- sort(list, decreasing = FALSE)
  avg <- mean(diff(list,1))
  return(avg)
}

exclude <- c()
airbox_head <- c("Date", "Time", "device_id", "PM2.5", "PM10", "PM1", "Temperature", "Humidity", "lat", "lon")
taiwan <- readOGR("/Users/sherry/Desktop/taiwan_airpollution/gadm36_TWN_shp/gadm36_TWN_0.shp")
airbox_processed <- data.frame(Date <- c(), Time <- c(),
                         device_id <- c(), PM2.5 <- c(),
                         PM10 <- c(), PM1 <- c(),
                         Temperature <- c(), Humidity <- c(),
                         lat <- c(), lon <- c(),
                         onland <- c())

#loop through the 29,915,720 records using foreach package, orginal loop will be a function
a = 0

for (a in 0:29){
  #stime <- Sys.time()
  airbox_raw <- read.csv("AirBox_v2.csv", stringsAsFactors = FALSE, header = FALSE, skip = a*1000000+2, nrow = 1000000)
  names(airbox_raw) <- airbox_head
  airbox_raw <- airbox_raw[airbox_raw$lat >= -90 & airbox_raw$lat <= 90 & airbox_raw$lon <= 180 & airbox_raw$lon >= -180, ]
  loc <- airbox_raw[c("device_id", "lat", "lon")]
  coordinates(loc) <- ~lon+lat
  proj4string(loc) <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
  loc <- loc %over% taiwan
  airbox_raw$onland <- loc$NAME_0 == "Taiwan"
  before <- nrow(airbox_raw)
  airbox_raw <- airbox_raw[!is.na(airbox_raw$onland), ]
  #world <- map("world")
  #point(airbox_raw$lat, airbox_raw$lon, col = "red", cex = 16)
  #airbox_raw <- airbox_raw[airbox_raw$Temperature >= 0, ]
  #airbox_raw <- airbox_raw[airbox_raw$Humidity <= 100,]
  after <- before - nrow(airbox_raw)
  exclude <- c(exclude, after)
  airbox_processed <- rbind(airbox_processed, airbox_raw)
  rm(airbox_raw)
  rm(loc)
  a = a+1
  #Sys.time() - stime
}

date <- unique(airbox_processed$Date)
date <- as.Date(date)
airbox_processed <- airbox_processed[-11]

#remove taiwan shapefile and use ggmap
map <- get_map(location = "taiwan", zoom = 7, maptype = "terrain")

#check less than 0 degree points
temp <- airbox_processed[airbox_processed$Temperature <= 0, ]
summary(temp)
ggmap(map) + 
  geom_point(
    aes(x = lon, y = lat), color = "black",
    data = temp, alpha = 0.5, na.rm = TRUE
  )
subset <- airbox_processed[airbox_processed$device_id == unique(temp$device_id)[1], ]
summary(subset[subset$Temperature <= 0, ])
summary(subset[subset$Temperature >  0, ])
#indicates that less than 0 degree doesn't make sense
airbox_processed <- airbox_processed[airbox_processed$Temperature >0, ]

#check more than abnormal humidity
p1 <- hist(airbox_processed$Humidity[airbox_processed$Humidity <= 0], breaks = 10)
sum(p1$counts)
p1$counts <- p1$density
plot(p1, main = "Humidity density graph", xlab = "Humidity", col = rgb(1, 0, 1, 1/4))

p1 <- hist(airbox_processed$Humidity[airbox_processed$Humidity > 100], breaks = 10)
sum(p1$counts)
p1$counts <- p1$density
plot(p1, main = "Humidity density graph", xlab = "Humidity", col = rgb(1, 0, 1, 1/4))
subset_temp <- airbox_processed[airbox_processed$Humidity <= -10 | airbox_processed$Humidity >= 200, ]
airbox_processed <- airbox_processed[airbox_processed$Humidity > -10 & airbox_processed$Humidity < 200, ]

#Spatial and Temporal Anomaly dection
#Some devices have more than one locations so device id doesn't bear unique geocoding info
length(unique(airbox_processed$device_id))
temp <- aggregate(airbox_processed$lat, by = list(airbox_processed$device_id), unique)
temp[order(lengths(temp$x), decreasing = TRUE), ]
sum(lengths(temp$x) >1)
temp[lengths(temp$x) ==max(lengths(temp$x)), ]


#find spastial anomaly radius range.
station <- airbox_processed[c("device_id","lat", "lon")]
station <- station[!duplicated(paste(station$lat, station$lon)), ]
ggmap(map) + 
  geom_point(
    aes(x = lon, y = lat), color = "black",
    data = station, size = 0.2, na.rm = TRUE
  )

#sstime <- Sys.time()
#find the distance for every two stations
station_distance <- distm(station[c("lon","lat")], fun = distHaversine)/1000
#Sys.time() - sstime #Time difference of 7.971666 secs
p1 <- hist(station_distance[station_distance < 350], breaks = 20)
p1$counts <- p1$density
p2 <- density(station_distance[station_distance < 350], bw = 15)
plot(p1, main = "Station distance density graph", xlab = "Station distance", col = rgb(1, 0, 1, 1/4))
lines(p2, col = rgb(1, 0, 1, 1))

#use the first peak
p2 <- cbind(p2$x, p2$y)
#find the distance that bears the first negative diff
radius <- round(p2[which(diff(p2[, 2], 1) <= 0)[1], 1])

#temperal data processing
airbox_processed$unix_time <- paste(airbox_processed$Date, airbox_processed$Time, "GMT")
airbox_processed$unix_time <- as.numeric(as.POSIXct(airbox_processed$unix_time))

#Duplicate in data
airbox_processed$ref <- paste(airbox_processed$device_id, airbox_processed$unix_time)
airbox_processed <- airbox_processed[!duplicated(airbox_processed$ref), ]
airbox_processed <- airbox_processed[-12]
#write.csv(airbox_processed, "airbox_processed.csv")

#temporal detection
airbox_processed <- airbox_processed[order(airbox_processed$device_id, airbox_processed$unix_time), ]
#keep track of the missing value
device_id <- unique(airbox_processed$device_id)
na_stat <- c()
temporal_anomaly <- c()
#threshold for continue time is 450s.
interval <- 450
#determine a good abnormal pm2.5 diff threshold
a = 1
for (a in 1:length(device_id)){
  temp <- airbox_processed[airbox_processed$device_id == device_id[a], ]
  temp$time_diff <- diff(c(0, temp$unix_time), 1)
  temp <- temp[temp$time_diff <= interval]
  temp$temperal_anomaly[temp$lowtime_diff == FALSE] <- NA
  temp$temperal_anomaly[temp$lowtime_diff == TRUE & temp$pm25_diff == FALSE] <- TRUE
  temp$temperal_anomaly[temp$lowtime_diff == TRUE & temp$pm25_diff == TRUE] <- FALSE
  temporal_anomaly <- c(temporal_anomaly, temp$temperal_anomaly)
  na_stat <- c(na_stat, round(sum(temp$lowtime_diff)/length(temp$lowtime_diff), 2))
}

a = 1
for (a in 1:length(device_id)){
  temp <- airbox_processed[airbox_processed$device_id == device_id[a], ]
  temp$time_diff <- diff(c(0, temp$unix_time), 1)
  temp$pm25_diff <- diff(c(0, temp$PM2.5), 1)
  temp$lowtime_diff <- temp$time_diff <= interval
  temp$lowpm_diff <- abs(temp$pm25_diff) <=2
  temp$temperal_anomaly[temp$lowtime_diff == FALSE] <- NA
  temp$temperal_anomaly[temp$lowtime_diff == TRUE & temp$pm25_diff == FALSE] <- TRUE
  temp$temperal_anomaly[temp$lowtime_diff == TRUE & temp$pm25_diff == TRUE] <- FALSE
  temporal_anomaly <- c(temporal_anomaly, temp$temperal_anomaly)
  na_stat <- c(na_stat, round(sum(temp$lowtime_diff)/length(temp$lowtime_diff), 2))
}
airbox_processed$temporal_anomaly <- temporal_anomaly
count <- table(airbox_processed$temporal_anomaly, useNA = "always")/length(airbox_processed$temporal_anomaly)
na_stat <- data.frame(device_id, na_stat)
#barplot(count, main = "Temporal Anomaly", col = rgb(1, 0, 1, 1/4))

temp <- airbox_processed[airbox_processed$temporal_anomaly == TRUE & !is.na(airbox_processed$temporal_anomaly), ]
temp[3034570:3034585, ]



