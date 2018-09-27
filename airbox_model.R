#Perform random effect panel data analysis and find correlations

library(plm)

setwd("/Users/sherry/Desktop/taiwan_airpollution/airbox/")

airbox_processed <- read.csv("airbox_processed.csv", stringsAsFactors = FALSE)
names(airbox_processed)
#stations <- airbox_processed[c("device_id", "lon", "lat")]
#stations <- stations[!duplicated(stations$device_id), ]

#remove unused variables
model_data <- subset(airbox_processed, select = -c(Time, PM10, PM1, lat, lon, unix_time))
#names(model_data)
model_data <- model_data[!is.na(model_data$linkou_second_change), ]
summary(model_data)
#Capacity and capacity change. Chnage of previous two days
#select the closest and the second colsest coal fire plant
plant_data <- model_data[12:42]
dist_slice <- plant_data[1:6]
cap_slice <- plant_data[c("linkou_cap", "taichung_cap", "hsinta_cap", "talin_cap", "hoping_cap", "miaoliao_cap")]
cap_first_change <- plant_data[c("linkou_first_change", "taichung_first_change", "hsinta_first_change",
                                 "talin_first_change", "hoping_first_change", "mailiao_first_change")]
cap_second_change <- plant_data[c("linkou_second_change", "taichung_second_change", "hsinta_second_change",
                                 "talin_second_change", "hoping_second_change", "mailiao_second_change")]
wind <- plant_data[c("linkou_wind", "taichung_wind", "hsinta_wind", "talin_wind", "hoping_wind", "mailiao_wind")]
first_min <- apply(dist_slice, 1, min)
first_plant <- data.frame(cbind(first_min, apply(data.frame(dist_slice == first_min) * cap_slice, 1, sum), 
                     apply(data.frame(dist_slice == first_min) * cap_first_change, 1, sum), 
                     apply(data.frame(dist_slice == first_min) * cap_second_change, 1, sum),
                     apply(data.frame(dist_slice == first_min) * wind, 1, sum)))
summary(first_plant)
names(first_plant) <- c("first_dist", "first_cap", "first_first_change", "first_second_change", "first_wind")
dist_slice[dist_slice == first_min] <- NA
second_min <- apply(dist_slice, 1, function(x) {min(x, na.rm = TRUE)})
dist_slice <- plant_data[1:6]
second_plant <- data.frame(cbind(second_min, apply(data.frame(dist_slice == second_min) * cap_slice, 1, sum), 
                      apply(data.frame(dist_slice == second_min) * cap_first_change, 1, sum),
                      apply(data.frame(dist_slice == second_min) * cap_second_change, 1, sum),
                      apply(data.frame(dist_slice == second_min) * wind, 1, sum)))
names(second_plant) <- c("second_dist", "second_cap", "second_first_change", "second_second_change", "second_wind")
summary(second_plant)
model_data <- cbind(model_data[1:11], first_plant, second_plant)
summary(model_data)
#write.csv(model_data, "model_data2.csv", row.names = FALSE)
model_data <- read.csv("model_data2.csv", stringsAsFactors = FALSE)
#plot to check temporal anamaly
#subset <- model_data[!is.na(model_data$temporal_anomaly) & model_data$temporal_anomaly == FALSE & model_data$PM2.5 <=3000, c("PM2.5", "first_cap")]
#plot(x = subset$first_cap, y = subset$PM2.5)
#anomaly <- model_data[model_data$PM2.5 >3000, ]
#test models with plotting
#map <- get_map(location = "taiwan", zoom = 7, maptype = "terrain")
#ggmap(map) + 
#  geom_point(
#    shape = 17,
#    aes(x = lon, y = lat), color = "black",
#    data = coal_plant, alpha = 1, na.rm = TRUE
#  ) +
#  geom_point(
#    aes(x = lon, y = lat, shape = as.factor(temporal_anomaly)), color = "red",
#    data = anomaly, alpha = 1, na.rm = TRUE
#  )
#summary(anomaly)
#table(anomaly$device_id)
#Over 3000 points are omitted because they may be wrong entry
model_data <- model_data[model_data$PM2.5 <= 3000, ]
#aggregate(model_data$PM2.5, by = list(model_data$temporal_anomaly), mean)
#subset <- model_data[is.na(model_data$temporal_anomaly), ]
#mean(subset$PM2.5) #28.13
#temporal dummy
temp_dummy <- model_data$temporal_anomaly == TRUE & !is.na(model_data$temporal_anomaly)
#aggregate(model_data$PM2.5, by = list(model_data$spatial_relative_degree), mean)
high_sp_dummy <- model_data$spatial_relative_degree == "High" & !is.na(model_data$spatial_relative_degree)
low_sp_dummy <- model_data$spatial_relative_degree == "Low" & !is.na(model_data$spatial_relative_degree)
dummy <- cbind(temp_dummy, high_sp_dummy, low_sp_dummy)
model_data <- subset(model_data, select = -c(temporal_anomaly, spatial_relative_degree, spatial_anomaly, sp_tem_anomaly))
model_data <- cbind(model_data, dummy)


#model_data <- model_data[-16]
#explore some plots
#subset <- model_data[c("first_change", "second_change")]
#subset <- subset[!duplicated(c("first_change", "second_change")), ]
#set.seed(13)
#subset <- model_data[sample(1:20365749, 10000, replace = FALSE), c("PM2.5", "first_cap", "second_cap")]
#plot(subset$second_cap, subset$PM2.5)
#test for co-lineary
x <- model.matrix(~PM2.5+Temperature+Humidity+agwind+first_min+first_cap+first_change+second_min+second_cap+second_change+temp_dummy+high_sp_dummy+low_sp_dummy - 1, data = model_data)
ncol(x) == qr(x)$rank #independent

head(model_data)
model_data <- model_data[-6]
#prepare data for panel data analyis
model_data$date_device <- paste(model_data$Date, model_data$device_id)
set1 <- aggregate(model_data[3:16], by = list(model_data$date_device), mean)
temp_dummy <- aggregate(model_data$temp_dummy, by = list(model_data$date_device), sum)
high_sp_dummy <- aggregate(model_data$high_sp_dummy, by = list(model_data$date_device), sum)
low_sp_dummy <- aggregate(model_data$low_sp_dummy, by = list(model_data$date_device), sum)
trans <- data.frame(table(model_data$date_device))
temp_dummy <- temp_dummy$x/trans$Freq > 0.5
high_sp_dummy <- high_sp_dummy$x/trans$Freq > 0.5
low_sp_dummy <- low_sp_dummy$x/trans$Freq > 0.5
Date <- sub("\\s+\\S+$", "", set1$Group.1)
device <- sub("^\\S+\\s+", "", set1$Group.1)

model <- cbind(data.frame(cbind(Date, device)), set1, temp_dummy, high_sp_dummy, low_sp_dummy)
#model$Date <- as.character(model$Date)
#model$device <- as.character(model$device)
#sapply(model, class)
model <- model[-3]
summary(model)

pdata <- pdata.frame(model, c("device", "Date"))
summary(model$PM2.5)
summary(model[4:ncol(model)])
Y <- model$PM2.5
X <- as.matrix(model[4:ncol(model)])

# Pooled OLS estimator
pooling <- plm(Y ~ X, data=pdata, model= "pooling")
summary(pooling)

# Between estimator
between <- plm(Y ~ X, data=pdata, model= "between")
summary(between)

# First differences estimator
#firstdiff <- plm(Y ~ X, data=pdata, model= "fd")
#summary(firstdiff)

# Fixed effects or within estimator
 
fixed <- plm(Y ~ X, data=pdata, model= "within")
summary(fixed)

# Random effects estimator
random <- plm(Y ~ X, data=pdata, model= "random")
summary(random)

# LM test for random effects versus OLS
plmtest(pooling)

# LM test for fixed effects versus OLS
pFtest(fixed, pooling)

# Hausman test for fixed versus random effects model
phtest(random, fixed)

copytable(random$coefficients)
