#ploting coal power plant and other color coded information
library(geosphere)
library(ggplot2)
library(ggmap)

setwd("/Users/sherry/Desktop/taiwan_airpollution/airbox")
airbox_processed <- read.csv("airbox_processed.csv", stringsAsFactors = FALSE)
airbox_processed <- subset(airbox_processed, select  = c("Date", "Time", "device_id", "PM2.5", "lat", "lon","unix_time",
                                                         "temporal_anomaly", "spatial_relative_degree",  "spatial_anomaly"))
#google <- subset(airbox_processed, select = c(Date, device_id, PM2.5, lat, lon, agwind, linkou_cap, linkou_first_change,
#                                              taichung_cap, taichung_first_change, hsinta_cap, hsinta_first_change,
#                                              talin_cap, talin_first_change, hoping_cap, hoping_first_change,
#                                              miaoliao_cap, mailiao_first_change))

google$date_device <- paste(google$Date, google$device_id)
google <- google[!is.na(google$linkou_first_change), ]
google <- aggregate(google[3:18], by = list(google$date_device), mean)

google$date <- sub("\\s+\\S+$", "", google$Group.1)
google$device <- sub("^\\S+\\s+", "", google$Group.1)

coal_plant <- data.frame(name <- c("Linkou", "Taichung", "Hsinta", "Talin", "Hoping", "Mailiao"),
                         lat <- c(25.121, 24.213, 22.856, 22.536, 24.3075, 23.798),
                         lon <- c(121.298, 120.481, 120.197, 120.336, 121.763, 120.202))
names(coal_plant) <- c("name", "lat", "lon")
plant_capacity <- read.csv("coalplant_stat.csv", stringsAsFactors = FALSE)
plant_capacity <- plant_capacity[1:365, ]

#plot data for entire year
date <- unique(google$date)

a = 1
for (a in 1:length(date)){
  title <- date[a]
  temp <- ggmap(map) + ggtitle(title) +
    geom_point(
      shape = 16,
      aes(x = lon, y = lat, color = PM2.5),
      data = google[google$date == date[a], ], alpha = .8, size = 0.8, na.rm = T) + 
    scale_color_gradientn(limits = c(0, 150), colors = c("springgreen3", "brown")) +
    geom_point(
      shape = 17, 
      aes(x = lon, y = lat),
      data= coal_plant,
      alpha = 1, size = 2
    )
  ggsave(filename = paste(title, ".png", sep = ""), plot = temp, width = 5, height = 5, unit = "in", dpi = 300)
}


time <- sub(":(.*)", "", airbox_processed$Time)
time[time %in% c("00", "01", "02", "03", "04", "05", "06", "07")] <- "1"
time[time %in% c("08", "09", "10", "11", "12", "13", "14", "15")] <- "2"
time[time %in% c("16", "17", "18", "19", "20", "21", "22", "23")] <- "3"

airbox_processed$Time <- time
airbox_processed$date_device <- paste(airbox_processed$Date, airbox_processed$Time, airbox_processed$device_id)
station <- airbox_processed[!duplicated(airbox_processed$device_id), c("lon", "lat")]
#Coal plant/station geo plot
map <- get_map(location = c(mean(lon), mean(lat)), zoom = 7, maptype = "terrain")
temp <- ggmap(map) + ggtitle("Airbox Monitoring Points") +
  geom_point(
    shape = 16, 
    aes(x = lon, y = lat),
    data= station,
    alpha = 1, size = 0.3
  )
ggsave(filename = "station.png", plot = temp, width = 5, height = 5, unit = "in", dpi = 300)

#change plot
#summary(plant_capacity)
date <- plant_capacity$Date[-1]
plant_change <- data.frame(apply(plant_capacity[2:7], 2, function(x){diff(x, 1, 1)}))
#summary(plant_change)
max_change <- sapply(plant_change, function(x) {which(x == max(x))[1]})
min_change <- sapply(plant_change, function(x) {which(x == min(x))[1]})

plant <- c("Linkou", "Taichung", "Hsinta", "Talin", "Hoping", "Mailiao")
a = 1
for (a in 1:length(plant)){
  select <- date[seq(max_change[[plant[a]]]-2, max_change[[plant[a]]]+2, by = 1)]
  subset <- airbox_processed[airbox_processed$Date %in% select, ]
  subset <- aggregate(subset[4:6], by = list(subset$date_device), mean)
  subset$Group.1 <- sub("\\s+\\S+$", "", subset$Group.1)
  subset$PM2.5 <- as.numeric(subset$PM2.5)
  subset$lat <- as.numeric(subset$lat)
  subset$lon <- as.numeric(subset$lon)
  select <- unique(subset$Group.1)
  b = 1
  for (b in 1:length(select)){
    (title <- paste(plant[a], select[b]))
    temp <- ggmap(map) + ggtitle(title) +
      geom_point(
        shape = 16,
        aes(x = lon, y = lat, color = PM2.5),
        data = subset[subset$Group.1 == select[a], ], alpha = .8, size = 0.8, na.rm = T) + 
      scale_color_gradientn(limits = c(0, 150), colors = c("springgreen3", "brown"))  +
      geom_point(
        shape = 17, 
        aes(x = lon, y = lat),
        data= coal_plant[coal_plant$name == plant[a], ],
        alpha = 1, size = 2
      )
    ggsave(filename = paste(title, ".png", sep = ""), plot = temp, width = 5, height = 5, unit = "in", dpi = 300)
    b = b+1
  }
  a = a+1
}

a = 1
for (a in 1:length(plant)){
  select <- date[seq(max_change[[plant[a]]]-2, min_change[[plant[a]]]+2, by = 1)]
  subset <- airbox_processed[airbox_processed$Date %in% select, ]
  subset <- aggregate(subset[4:6], by = list(subset$date_device), mean)
  subset$Group.1 <- sub("\\s+\\S+$", "", subset$Group.1)
  subset$PM2.5 <- as.numeric(subset$PM2.5)
  subset$lat <- as.numeric(subset$lat)
  subset$lon <- as.numeric(subset$lon)
  select <- unique(subset$Group.1)
  b = 1
  for (b in 1:length(select)){
    (title <- paste(plant[a], select[b]))
    temp <- ggmap(map) + ggtitle(title) +
      geom_point(
        shape = 16,
        aes(x = lon, y = lat, color = PM2.5),
        data = subset[subset$Group.1 == select[a], ], alpha = .5, na.rm = T) + 
      scale_colour_manual(values = cols) +
      geom_point(
        shape = 17, 
        aes(x = lon, y = lat),
        data= coal_plant[coal_plant$name == plant[a], ],
        alpha = 1, size = 2
      )
    ggsave(filename = paste(title, ".png", sep = ""), plot = temp, width = 5, height = 5, unit = "in", dpi = 300)
    b = b+1
  }
  a = a+1
}
