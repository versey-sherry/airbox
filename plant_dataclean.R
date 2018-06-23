setwd("/Users/sherry/Desktop/taiwan_airpollution/airbox/")

coal_plant <- data.frame(name <- c("Linkou", "Taichung", "Hsinta", "Talin", "Hoping", "Mailiao"),
                         lat <- c(25.121, 24.213, 22.856, 22.536, 24.3075, 23.798),
                         lon <- c(121.298, 120.481, 120.197, 120.336, 121.763, 120.202))
plant_capacity <- read.csv("coalplant_stat.csv", stringsAsFactors = FALSE)

#summary(plant_capacity)
linkou <- matrix(rep(c(lon[1], lat[1]), times = nrow(plant_capacity)), ncol = 2, byrow = TRUE)
taichung <- matrix(rep(c(lon[2], lat[2]), times = nrow(plant_capacity)), ncol = 2, byrow = TRUE)
hsinta <- matrix(rep(c(lon[3], lat[3]), times = nrow(plant_capacity)), ncol = 2, byrow = TRUE)
talin <- matrix(rep(c(lon[4], lat[4]), times = nrow(plant_capacity)), ncol = 2, byrow = TRUE)
hoping <- matrix(rep(c(lon[5], lat[5]), times = nrow(plant_capacity)), ncol = 2, byrow = TRUE)
mailiao <- matrix(rep(c(lon[6], lat[6]), times = nrow(plant_capacity)), ncol = 2, byrow = TRUE)

linkou <- cbind(plant_capacity[1], data.frame(cbind(linkou, plant_capacity$Linkou)))
taichung <- cbind(plant_capacity[1], data.frame(cbind(taichung, plant_capacity$Taichung)))
hsinta <- cbind(plant_capacity[1], data.frame(cbind(hsinta, plant_capacity$Hsinta)))
talin <- cbind(plant_capacity[1], data.frame(cbind(talin, plant_capacity$Talin)))
hoping <- cbind(plant_capacity[1], data.frame(cbind(hoping, plant_capacity$Hoping)))
mailiao <- cbind(plant_capacity[1], data.frame(cbind(mailiao, plant_capacity$Mailiao)))


