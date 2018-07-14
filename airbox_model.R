library(plm)

setwd("/Users/sherry/Desktop/taiwan_airpollution/airbox/")

#airbox_processed <- read.csv("airbox_processed.csv", stringsAsFactors = FALSE)
airbox_processed <- airbox_processed[-1]
names(airbox_processed)

#remove unused variables
model_data <- subset(airbox_processed, select = -c(Time, PM10, PM1, lat, lon, unix_time))
#names(model_data)
model_data <- model_data[!is.na(model_data$linkou_change), ]

#select the closest and the second colsest coal fire plant
plant_data <- model_data[12:29]
dist_slice <- plant_data[1:6]
cap_slice <- plant_data[c("linkou_cap", "taichung_cap", "hsinta_cap", "talin_cap", "hoping_cap", "mailiao_cap")]
cap_change <- plant_data[c("linkou_change", "taichung_change", "hsinta_change", "talin_change", "hoping_change", "mailiao_change")]
first_min <- apply(dist_slice, 1, min)
first_plant <- cbind(first_min, apply(data.frame(dist_slice == first_min) * cap_slice, 1, sum), apply(data.frame(dist_slice == first_min) * cap_change, 1, sum))
names(first_plant) <- c("first_dist", "first_cap", "first_change")
dist_slice[dist_slice == first_min] <- NA
second_min <- apply(dist_slice, 1, function(x) {min(x, na.rm = TRUE)})
dist_slice <- plant_data[1:6]
second_plant <- cbind(second_min, apply(data.frame(dist_slice == second_min) * cap_slice, 1, sum), apply(data.frame(dist_slice == second_min) * cap_change, 1, sum))
names(second_plant) <- c("second_dist", "second_cap", "second_change")
model_data <- cbind(model_data[1:11], first_plant, second_plant)
#write.csv(model_data, "model_data.csv")


l1 <- lm(PM2.5 ~ first_min + first_cap + second_min + second_cap, data = model_data)
summary(l1)
