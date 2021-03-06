## Correlation Between Particulate Matter (PM2.5) and Coal Power Plant Operation Using Public Participation Air Quality Sensing Data

### Abstract

Environmental problems such as carbon emissions and air pollution caused by coal power plants are frequently subjected to public and scientific attention. Air pollution from fine particulate matter (PM2.5) is especially serious due to the high level of risk it presents to human health and the climate. Airbox is a device developed by Academia Sinica to allow the general public to monitor ambient air quality and enhance public engagement in air quality sensing. This paper uses Airbox air monitoring data from 2017 to perform panel data analysis to find the correlation between air pollution and coal power plant operations. The analysis shows that PM2.5 concentration at monitoring points is positively correlated with the operating capacity and the previous-day capacity change of the nearest coal power plant. The result also shows that PM2.5 concentration is positively correlated with wind speed at the monitoring points and negatively correlated with distance from monitoring points.

### Introduction
Coal power is one of the main reasons for air pollution and climate change. Faced with the challenge of dealing with climate change and air pollution, government all over the world are taking active measures to decrease the dependency of coal power in power production. Although the local government in Taiwan has announced that it would take actions to accelerate energy transformation and boost renewable energy development, coal power is still the main source of Taiwan’s power production. According to [Taiwan Energy White Paper](http://energywhitepaper.tw/reference/), coal power production made up 45.4% of Taiwan’s total power production.

![power production ratio](https://github.com/versey-sherry/airbox/blob/master/pics/Picture1.png)

With the increasing awareness of PM2.5 and health impacts of air pollution among the general public, people start to care more about the level of PM2.5 they are exposed to. However, official air quality data is only published every hour and the number of monitoring points is very limited. Therefore, people start to set up their own monitoring points to monitor air quality as part of Location aware sensor system, LASS movement. At the moment, one of the popular devices is Airbox developed by IIS, SINICA. There are over 2,000 Airbox devices in Taiwan and the devices will return real-time air quality data every five minutes. Therefore, the data enables more detailed research into air pollution including its potentially related factors and movement.

In this research, 2017 airbox data is used to see if there is any correlation between the level of PM2.5 and coal plant operations.

### Data Summary and Methods
#### Air Pollution Monitoring Data
There are in total 29,915,720 entries in the raw data. After cleaning up the points that are not in Taiwan and other abnormal points, there are 26,061,705 entries left in the dataset. Following the basic concept described in *Big Data Analysis in Air Pollution Using Airbox Data* by IIS, SINICA, dummy variables for temporal anomaly and spatial anomaly are created.

* Temporal Anomaly

If the absolute difference between two consecutive entries is more than the PM2.5 threshold value, the later one will be considered as a temporal anomaly.

Since the time difference between two consecutive entries varies, a histogram of time differences is examined to find the proper threshold time difference to realistically see two entries as consecutive. The threshold time difference chosen in this research is 450s and the same method is used to determine the PM2.5 threshold value.

* Spatial Anomaly

At a certain time, if the absolute difference between the value at target point and the average value among neighboring points is more than the PM2.5 threshold value, the value at target point will be considered as a spatial anomaly. If the difference is positive, then the value at the target point will be considered as a spatially high anomaly; otherwise, a spatially low anomaly.

To find the threshold radius to determine neighboring points for a target point, point locations are plotted onto Taiwan map and clusters of points are quite obvious.

![point locations](https://github.com/versey-sherry/airbox/blob/master/pics/Picture2.png)

The distance between two points is calculated with Haversine and distances less than 350km are plotted onto a histogram with a kernel density estimation. The first peak of the graph represents 23km as shown in the plot. Therefore, 23km is selected to be the max value for the search of best threshold radius.

![histogram](https://github.com/versey-sherry/airbox/blob/master/pics/Picture3.png)

If target monitoring point has less than 3 other monitoring points with n km radius, then this target point will be a loner with no neighbors. The percentage of loner points increases when n decreases so an optimal n needs to be small enough but not too small that the percentage of loner points is too high. Inspired by elbow chart commonly used in finding optimal cluster numbers, a sequence of numbers ranges from 1km to 23km by 0.5km, is used to check the percentage of loner points.

![elbow distance](https://github.com/versey-sherry/airbox/blob/master/pics/Picture4.png)

Using the same concept as elbow chart, the elbow part contains the optimal number for n, and after n=3, the decrease rate of percentage becomes slower. So 3km is used to determine neighboring points and 4mg/m^3.

#### Coal Plant Operation Data
This research uses 2017 coal operation data from [Taipower](https://www.taipower.com.tw/tc/page.aspx?mid=210&cid=340&cchk=eac92988-526f-44e3-a911-1564395de297). Change in daily capacity difference is calculatd to be the current day change of target day, and the change of previous day is assigned to be the previous day change of target day.

![power plant](https://github.com/versey-sherry/airbox/blob/master/pics/Picture5.png)

Distance between all coal plants and monitoring points are calculated with Haversine to find the closest coal plant and the second closest coal plant for the monitoring points.

#### Wind Speed Data
[2017 Monthly wind speed data from NASA](https://disc.gsfc.nasa.gov/daac-bin/FTPSubset2.pl) is used in this research. The aggreagated wind speeds at all monitoring point and coal plant locations are calculated.

### Hypotheses
* H1: Ceteris paribus, the level of PM2.5 is positively correlated with the running capacity of the closest coal plant.
Air pollution from coal plants usually results from the burning of coal. Therefore, the more capacity the power plant is running, the more air pollution it would produce.

* H2a: Ceteris paribus, the level of P2.5 is positively correlated with the current day change of running capacity of the closest coal plant.

* H2b: Ceteris paribus, the level of P2.5 is positively correlated with the previous day change of running capacity of the closest coal plant.

* H3a: Ceteris paribus, the level of PM2.5 is positively correlated with the monitoring point wind speed.

* H3b: Ceteris paribus, the level of PM2.5 is negatively correlated with the distance between monitoring points and closest coal plant.
In [Jinghua Wang and Susumu Ogawa's research](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4555266/
), they identify threshold wind speed for the relations between wind speed and level of PM2.5. When wind speed is over 3m/s, level of PM2.5 is positively correlated with wind speed but the oposite when wind speed is less than 3m/s. From the summary of data, average wind speed is 4.76m/s, therefore, it is hypothesized that the level of PM2.5 is positively correlated with the monitoring point wind speed and negatively correlated with the distance between monitoring points and closest coal plant.

### Result and Discussion
Result from random effect panel data model is the following:
![table](https://github.com/versey-sherry/airbox/blob/master/pics/Picture7.png)

From the table above, we can accept H1, H2b, H3a and H3b but reject H2a. 

### Conclusions
From the random effect panel data model, the running capacity of closest coal plant is positively correlated with the level of PM2.5. The previous day change of running capacity is positively correlated with the level of PM2.5, which may indicate that the effect from change in running capacity may be delayed.

### Future Work
More accurate wind speed should be used to improve the accuracy of the model and effected wind speed should be calculated by taking the wind speed projected along the straight line connecting coal plants and the monitoring points. If possible, 3D geographic information into consideration, maybe some more control variables into the model.

