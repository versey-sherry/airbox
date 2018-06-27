library(geosphere)
library(sp)
library(rgdal)
library(maptools)
library(maps)
library(ggmap)
library(doParallel)
library(foreach)

#cl <- makePSOCKcluster(detectCores() - 1)
registerDoParallel(6)

setwd("/Users/sherry/Desktop/taiwan_airpollution/airbox/")

coal_plant <- data.frame(name <- c("Linkou", "Taichung", "Hsinta", "Talin", "Hoping", "Mailiao"),
                         lat <- c(25.121, 24.213, 22.856, 22.536, 24.3075, 23.798),
                         lon <- c(121.298, 120.481, 120.197, 120.336, 121.763, 120.202))
names(coal_plant) <- c("name", "lat", "lon")
plant_capacity <- read.csv("coalplant_stat.csv", stringsAsFactors = FALSE)

map <- get_map(location = "taiwan", zoom = 7, maptype = "terrain")
ggmap(map) + 
  geom_point(
    aes(x = lon, y = lat, shape = "b"), color = "black", 
    data = coal_plant, alpha = 1, na.rm = TRUE
  )

#summary(plant_capacity)

airbox_processed <- airbox_processed[order(airbox_processed$unix_time, airbox_processed$device_id), ]

#create data frame of date and capacity
linkou <- cbind(plant_capacity[1], plant_capacity$Linkou)
names(linkou) <- c("Date", "linkou_cap")
change <- c(NA, diff(linkou[[2]], 1, 1))
linkou$linkou_change <- change
taichung <- cbind(plant_capacity[1], plant_capacity$Taichung)
names(taichung) <- c("Date", "taichung_cap")
change <- c(NA, diff(taichung[[2]], 1, 1))
taichung$taichung_change <- change
hsinta <- cbind(plant_capacity[1], plant_capacity$Hsinta)
names(hsinta) <- c("Date", "hsinta_cap")
change <- c(NA, diff(hsinta[[2]], 1, 1))
hsinta$hsinta_change <- change
talin <- cbind(plant_capacity[1],plant_capacity$Talin)
names(talin) <- c("Date", "talin_cap")
change <- c(NA, diff(talin[[2]], 1, 1))
talin$talin_change <- change
hoping <- cbind(plant_capacity[1], plant_capacity$Hoping)
names(hoping) <- c("Date", "hoping_cap")
change <- c(NA, diff(hoping[[2]], 1, 1))
hoping$hoping_change <- change
mailiao <- cbind(plant_capacity[1], plant_capacity$Mailiao)
names(mailiao) <- c("Date", "miaoliao_cap")
change <- c(NA, diff(mailiao[[2]], 1, 1))
mailiao$mailiao_change <- change

plant_data <- cbind(linkou, taichung[2:3], hsinta[2:3], talin[2:3], hoping[2:3], mailiao[2:3])
plant_data <- 

date <- data.frame(airbox_processed$Date)

names(date) <- "Date"
plant_data <- merge(date, plant_data, by = "Date")
airbox_processed <- cbind(airbox_processed, plant_data)

#plant distance calculation
airbox_processed <- airbox_processed[order(airbox_processed$unix_time, airbox_processed$device_id), ]
temp_station <- airbox_processed[ ,c("lon", "lat")]
plant_coor <- coal_plant[c("lon", "lat")]

#loop through all the plants to get the distance between stations and the plant (distance in km)

plant_distance <- data.frame(distm(temp_station, plant_coor, fun = distHaversine)/1000)
names(plant_distance) <- c("linkou_dist", "taichung_dist", "hsinta_dist", "talin_dist", "hoping_dist", "mailiao_dist")

airbox_processed <- cbind(airbox_processed, plant_distance)

#write.csv(airbox_processed, "airbox_processed.csv")
