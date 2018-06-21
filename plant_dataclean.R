setwd("/Users/sherry/Desktop/taiwan_airpollution/airbox/")

coal_plant <- data.frame(name <- c("Linkou", "Taichung", "Hsinta", "Talin", "Hoping", "Mailiao"),
                         lat <- c(25.121, 24.213, 22.856, 22.536, 24.3075, 23.798),
                         lon <- c(121.298, 120.481, 120.197, 120.336, 121.763, 120.202))
plant_capacity <- read.csv("coalplant_stat.csv", stringsAsFactors = FALSE)
#summary(plant_capacity)

