# Weather Station Data Processor

This script processes the ISD data into a more usable form.  Specifically it processes the FM-15 and FM-16 reports so that the data is ready for analysis by producing CSVs of mean weather observations aggregated to each hour and a geojson of station locations.  

A 126 page description of the raw ISD data can be found here:
https://www.ncei.noaa.gov/data/global-hourly/doc/isd-format-document.pdf

Requires the ISD data to be local to work.  Check out `isdDataDownloader.R` for help with that.

![windTimeseries](http://docwatson.ai/wp-content/uploads/2021/12/timeseriesExample.png)
