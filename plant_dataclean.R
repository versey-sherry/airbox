#clean up raw plant operating data for future modeling

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
    shape = 17,
    aes(x = lon, y = lat), color = "black",
    data = coal_plant, alpha = 1, na.rm = TRUE
  )

#summary(plant_capacity)

airbox_processed <- airbox_processed[order(airbox_processed$unix_time, airbox_processed$device_id), ]

#create data frame of date and capacity
#Different is the second day different because wind speed is low
linkou <- cbind(plant_capacity[1], plant_capacity$Linkou)
names(linkou) <- c("Date", "linkou_cap")
first_change <- c(NA, diff(linkou[[2]], 1, 1))
second_change <- c(NA, NA, diff(linkou[[2]], 1, 1))
second_change <- second_change[-length(second_change)]
linkou$linkou_first_change <- first_change
linkou$linkou_second_change <- second_change
taichung <- cbind(plant_capacity[1], plant_capacity$Taichung)
names(taichung) <- c("Date", "taichung_cap")
first_change <- c(NA, diff(taichung[[2]], 1, 1))
second_change <- c(NA, NA, diff(taichung[[2]], 1, 1))
second_change <- second_change[-length(second_change)]
taichung$taichung_first_change <- first_change
taichung$taichung_second_change <- second_change
hsinta <- cbind(plant_capacity[1], plant_capacity$Hsinta)
names(hsinta) <- c("Date", "hsinta_cap")
first_change <- c(NA, diff(hsinta[[2]], 1, 1))
second_change <- c(NA, NA, diff(hsinta[[2]], 1, 1))
second_change <- second_change[-length(second_change)]
hsinta$hsinta_first_change <- first_change
hsinta$hsinta_second_change <- second_change
talin <- cbind(plant_capacity[1],plant_capacity$Talin)
names(talin) <- c("Date", "talin_cap")
first_change <- c(NA, diff(talin[[2]], 1, 1))
second_change <- c(NA, NA, diff(talin[[2]], 1, 1))
second_change <- second_change[-length(second_change)]
talin$talin_first_change <- first_change
talin$talin_second_change <- second_change
hoping <- cbind(plant_capacity[1], plant_capacity$Hoping)
names(hoping) <- c("Date", "hoping_cap")
first_change <- c(NA, diff(hoping[[2]], 1, 1))
second_change <- c(NA, NA, diff(hoping[[2]], 1, 1))
second_change <- second_change[-length(second_change)]
hoping$hoping_first_change <- first_change
hoping$hoping_second_change <- second_change
mailiao <- cbind(plant_capacity[1], plant_capacity$Mailiao)
names(mailiao) <- c("Date", "miaoliao_cap")
first_change <- c(NA, diff(mailiao[[2]], 1, 1))
second_change <- c(NA, NA, diff(mailiao[[2]], 1, 1))
second_change <- second_change[-length(second_change)]
mailiao$mailiao_first_change <- first_change
mailiao$mailiao_second_change <- second_change

plant_data <- cbind(linkou, taichung[2:4], hsinta[2:4], talin[2:4], hoping[2:4], mailiao[2:4])

date <- data.frame(airbox_processed$Date)

names(date) <- "Date"
plant_data <- merge(date, plant_data, by = "Date")
plant_data <- plant_data[-1]
airbox_processed <- airbox_processed[1:23]
airbox_processed <- cbind(airbox_processed, plant_data)

#plant distance calculation
airbox_processed <- airbox_processed[order(airbox_processed$unix_time, airbox_processed$device_id), ]
temp_station <- airbox_processed[ ,c("lon", "lat")]
plant_coor <- coal_plant[c("lon", "lat")]

#loop through all the plants to get the distance between stations and the plant (distance in km)

plant_distance <- data.frame(distm(temp_station, plant_coor, fun = distHaversine)/1000)
names(plant_distance) <- c("linkou_dist", "taichung_dist", "hsinta_dist", "talin_dist", "hoping_dist", "mailiao_dist")

airbox_processed <- cbind(airbox_processed, plant_distance)

write.csv(airbox_processed, "airbox_processed.csv", row.names = FALSE)
