library(geosphere)
library(raster)
library(sp)
library(rgdal)
library(maptools)
library(maps)
library(ggmap)

setwd("/Users/sherry/Desktop/taiwan_airpollution")

copytable <- function(table){
  clip <- pipe("pbcopy", "w")
  write.table(table, sep = "，", file = clip)
  close(clip)
}

date <- c()
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
  date <- c(date, unique(airbox_raw$Date))
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

date <- unique(date)
date <- as.Date(date)
airbox_processed <- airbox_processed[-11]
write.csv(airbox_processed, "airbox_processed.csv")


#remove taiwan shapefile and use ggmap
map <- get_map(location = "taiwan", zoom = 8, maptype = "terrain")
ggmap(map) + 
  geom_point(
   aes(x = lon, y = lat, shape = "c"),
   data = temp, alpha = 0.5, na.rm = TRUE
   )
temp <- airbox_processed[airbox_processed$Temperature <= 0, ]
unique(temp$device_id)
subset_temp <- 

#debug until here.
check <- aggregate(airbox_raw$lat, by = list(airbox_raw$device_id), unique)
check[order(lengths(check$x), decreasing = TRUE),]
sum(lengths(check$x) >1)
