library(geosphere)
library(raster)
library(sp)
library(rgdal)
library(maptools)
library(maps)
library(ggmap)
library(doParallel)
library(foreach)

cl <- makePSOCKcluster(detectCores() - 1)
registerDoParallel(cl)

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

unique_length <- function(list){
  return(length(unique(list)))
}

#Parallel computing for sptial anomaly detection
spatial_dectect <- function(a, df, time_panel){
  temp <- df[df$time_panel == time_panel[a], ]
  temp_station <- temp[c("lon", "lat")]
  temp_distance <- distm(temp_station, fun = distHaversine)/1000
  temp_distance <- temp_distance >0 & temp_distance <= 3
  neighbor_num <- apply(temp_distance, 2, sum)
  temp_pm <- temp$PM2.5
  #operation goes by column
  temp_neighbor <- apply(temp_pm * temp_distance, 2, sum)/neighbor_num
  return(test <- temp_pm - temp_neighbor)
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
station_distance <- data.frame(distm(station[c("lon","lat")], fun = distHaversine)/1000)
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
#find the neighbor distance
near_test <- seq(1, 23, by = 0.5)
distance_test <-sapply(near_test, function(k) {sum(apply(station_distance <= k, 2, sum) <3)/nrow(station_distance)})
plot(near_test, distance_test, type = "b", pch = 19, frame = FALSE, 
     main = "Find Neighbor Distance",
     xlab = "Distance between two points",
     ylab = "Percentage of No Neighbor")

#neighbor distance is set to 3km
near <- 3

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
device_id <- unique(airbox_processed$device_id)

#threshold for continue time is 450s.
interval <- 450
#determine a good abnormal pm2.5 diff threshold
a = 1
pm_check <- data.frame(Var1 <- c(),
                       var2 <- c(),
                       Freq <- c())
for (a in 1:length(device_id)){
  temp <- airbox_processed[airbox_processed$device_id == device_id[a], ]
  temp$time_diff <- diff(c(0, temp$unix_time), 1)
  temp <- temp[temp$time_diff <= interval, ]
  temp$pm_diff <- diff(c(0, temp$PM2.5), 1)
  pm_check <- rbind(pm_check, data.frame(t(table(abs(temp$pm_diff)))))
}
pm_check <- pm_check[-1]
pm_check <- aggregate(pm_check$Freq, by = list(pm_check$Var2), sum)
pm_check <- pm_check[order(pm_check$x, decreasing = TRUE), ]
#From accumulated frequencies we can see that pm_threshold is 2.

#keep track of the missing value
na_stat <- c()
temporal_anomaly <- c()

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

#Spatial detection
airbox_processed <- airbox_processed[order(airbox_processed$unix_time, airbox_processed$device_id), ]
avg_time_diff <- aggregate(airbox_processed$unix_time, by = list(airbox_processed$device_id), avg_diff)
#hist(avg_time_diff$x[avg_time_diff$x <=10000], main = "Average Time Interval", xlab = "Less than 10000s interval")
#Round the unix time to the nearst 450s interval
time <- airbox_processed$unix_time - airbox_processed$unix_time[1]
airbox_processed$time_panel <- round(time/450)
timeslice_length <- aggregate(airbox_processed$device_id, by = list(airbox_processed$time_panel), unique_length)
#head(timeslice_length[order(timeslice_length$x, decreasing = TRUE),], 10)
#tail(timeslice_length[order(timeslice_length$x, decreasing = TRUE),], 10)
time_panel <- unique(airbox_processed$time_panel)
airbox_processed <- airbox_processed[order(airbox_processed$time_panel), ]
#stime <- Sys.time()
spatial_anomaly <- foreach(a = 1:length(time_panel), .combine = c, .packages = "geosphere") %dopar% spatial_dectect(a, airbox_processed, time_panel)
#Sys.time() - stime
#summary(spatial_anomaly)
hist(abs(spatial_anomaly)[which(abs(spatial_anomaly) < 10)], main = "Histgram of abs less than 10", xlab = "abs")
#spatial anomaly threshold is abs more than 4
spatial_relative_degree <- spatial_anomaly
spatial_relative_degree[spatial_relative_degree > 4] <- "High"
spatial_relative_degree[spatial_relative_degree <  -4] <- "Low"
spatial_relative_degree[spatial_relative_degree >= -4 & spatial_relative_degree <= 4] <- "Normal"
#table(spatial_relative_degree)
spatial_anomaly <- abs(spatial_anomaly)
spatial_anomaly[spatial_anomaly > 4] <- "TRUE"
spatial_anomaly[spatial_anomaly <= 4] <- "FALSE"
spatial_anomaly <- as.logical(spatial_anomaly)
#table(spatial_anomaly, useNA = "always")
airbox_processed$spatial_relative_degree <- spatial_relative_degree
airbox_processed$spatial_anomaly <- spatial_anomaly
airbox_processed$sp_tem_anomaly <- airbox_processed$temporal_anomaly & airbox_processed$spatial_anomaly
#table(airbox_processed$sp_tem_anomaly, useNA = "always")/nrow(airbox_processed)
#summary(airbox_processed)

write.csv(airbox_processed, "airbox_processed.csv")
