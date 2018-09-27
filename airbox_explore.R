#Explore the possiblility of this dataset and do some basic plotting
library(geosphere)
library(ggplot2)
library(ggmap)

setwd("/Users/sherry/Desktop/taiwan_airpollution")

copytable <- function(table){
  clip <- pipe("pbcopy", "w")
  write.table(table, sep = "，", file = clip)
  close(clip)
}


#coal fire plants location
coal_plant <- data.frame(name <- c("Linkou", "Taizhong", "Xingda", "Dalin", "Heping", "Mailiao"),
                         lat <- c(25.121, 24.213, 22.856, 22.536, 24.3075, 23.798),
                         lon <- c(121.298, 120.481, 120.197, 120.336, 121.763, 120.202))
names(coal_plant) <- c("name", "lat", "lon")

bad_boy <- data.frame(c("Taizhong"),
                    c(24.213),
                    c(120.481))
names(bad_boy) <- c("name", "lat", "lon")

#total row of LASS_v2.csv 45510747 rows, AirBox_v2.csv 29915720. Max row number is 1000000. Loop 
airbox_head <- c("Date", "Time", "device_id", "PM2.5", "PM10", "PM1", "Temperature", "Humidity", "lat", "lon")
airbox_raw <- read.csv("AirBox_v2.csv", stringsAsFactors = FALSE, header = FALSE, skip = 5000002, nrow = 1000000)
names(airbox_raw) <- airbox_head
unique(airbox_raw$Date)
max(airbox_raw$PM2.5)
head(sort(table(airbox_raw$PM2.5), decreasing = TRUE))
tail(sort(table(airbox_raw$PM2.5), decreasing = TRUE))

#explore
summary(airbox_raw)
sort(table(airbox_raw$Temperature), decreasing =FALSE)

#the plotting bit
p1 <- hist(airbox_raw$PM2.5, freq = FALSE, breaks = 50)
p1$counts <- p1$density
p2 <- density(airbox_raw$PM2.5, na.rm = TRUE)
plot(p1, main = "PM2.5 density graph", xlab = "pm2.5", col = rgb(1, 0, 1, 1/4))
lines(p2, col = rgb(1, 0, 1, 1))

#subset huge changes
(date <- unique(airbox_raw$Date)[2:10])
a = 1
subset <- airbox_raw[airbox_raw$Date == date[a], ]

#some map plotting first
#subset <- airbox_raw[airbox_raw$Date == "2017-01-02", ]'
map<-get_map(location = "taiwan", zoom=8, maptype = "terrain",
             color='bw')
#start_time <- Sys.time()
ggmap(map) + ggtitle(date[a]) + 
  geom_point(
  aes(x = lon, y = lat, shape = "c"),
  data = bad_boy, 
  size = 2
) + 
  geom_point(
  aes(x = lon, y = lat, color = PM2.5, shape = "a"),
  data = subset, alpha = .5, na.rm = T) +
  scale_color_gradient(low="red", high="black")
#end_time <- Sys.time()
#end_time - start_time

#Explore Taizhong subset
subset <- airbox_raw[airbox_raw$Date %in% date, ]
unique(subset$Date)
subset$dist <- distm(matrix(c(subset$lon, subset$lat), ncol = 2, byrow = FALSE), c(bad_boy$lon, bad_boy$lat), fun=distHaversine)/1e3
#50 km points and not
subset_small <- subset[subset$dist > 50, ]
aggregate(subset_small$PM2.5, by = list(subset_small$Date), mean, rm.na = TRUE)

