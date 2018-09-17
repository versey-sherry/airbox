# Airbox Data Analysis

This project was originated from my work in air pollution.

Environmental problems such as carbon emissions and air pollution caused by coal-fired power plants are frequently subject to public and scientific attention. Air pollution from fine particulate matter (PM2.5) is especially serious due to the high level of risk it presents to human health and the climate. Airbox is a device developed by Academia Sinica to allow the general public to monitor ambient air quality and enhance public engagement in air quality sensing. This paper uses Airbox air monitoring data from 2017 to perform panel data analysis to find the correlation between air pollution and coal-fired power plant operations. The analysis shows that PM2.5 concentration at monitoring points is positively correlated with the operating capacity and the previous-day capacity change of the nearest coal-fired power plant. The result also shows that PM2.5 concentration is positively correlated with wind speed at the monitoring points and negatively correlated with distance from monitoring points.

## What is Airbox and Why I Analyze its Data
Airbox is a small device developed by IIS, SINICA for air quality monitoring. People could actively participate is Location aware sensor system citizen science projects to monitor air quality. The large amount of data is collected for real-time air quality monitoring and future study in air pollution.

There are more than 2,000 Airbox devices set up in Taiwan and the device returns data every 5 mins. Therefore, the data enables more detailed research into air pollution including its potentially related factors and movement.

According to Taiwan Energy White Paper coal-fired power production made up 45.4% of Taiwan’s total power production. Coal power is one of the main reasons for air pollution and climate change. Faced with the challenge of dealing with climate change and air pollution, government all over the world are taking active measures to decrease the dependency of coal power in power production. Although the local government in Taiwan has announced that it would take actions to accelerate energy transformation and boost renewable energy development, coal power is still the main source of Taiwan’s power production. Therefore, I analyze the relations between the operation of coal-fired plants and the air pollution using Airbox data.

## Research Findings and Future Work
The paper was originally written in Chinese and presented at LASS annual gathering. I've translated the interesting part of it and put the [research findings here](https://github.com/versey-sherry/airbox/blob/master/research_finding.md)

I'd like to improve the model by using more accurate wind speed and calculate the wind speed effect by taking the wind speed projected along the straight line connecting coal-fired plants and the monitoring points. If possible, I'd like to take 3D geographic information into consideration, maybe some more control variables into the model.

## Authors

* **Sherry** - *Initial work* - [versey-sherry](https://github.com/versey-sherry/)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Yung-Jen Chen, thank you very much for coordinating this research project
* Cony Chang, thank you very much for the presentation and enabling me to conduct this research
* Johnny and Yoko, thank you for being very good kitties and supporting me with all dat cuteness and purring
* Special thanks to Strophy. Thank you so much for supporting me through and through
