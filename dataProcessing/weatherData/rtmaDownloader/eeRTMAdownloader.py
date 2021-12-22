#Import modules
import datetime
from datetime import timedelta, date
import os
from pathlib import Path
import requests
# Start Google Earth Engine
import ee
ee.Initialize()

# Enter the path of the destination folder
outputDir = r"./output"
#Enter the start date and the end date
startDate= datetime.date(2016, 1, 1)
endDate= datetime.date(2020, 12, 31)

#Function to create the date range from given dates
def daterange(startDate, endDate):
    for n in range(int ((endDate - startDate).days + 1)):
        yield startDate + timedelta(n)

max_items = 20
theTimes = ["%02d" %i for i in list(range(0,24,1))] 
varList = []

failedList = []
#Code to create foders for each day and subfolders for each hour. Then extract RTMA file for each hour and store in the respective folders.
for single_date in daterange(startDate, endDate):
    print("Downloading RTMA data for",single_date,"...")
    yearMonth=single_date.strftime("%Y%m")
    datestr=single_date.strftime("%Y%m%d")
    folderPath=yearMonth + '/' + datestr
    path=outputDir + str(yearMonth) 
    Path(path).mkdir(parents=True, exist_ok=True)
    path2=str(path) + '/' + datestr
    Path(path2).mkdir(parents=True, exist_ok=True)

    for aTime in theTimes:
      timeString = single_date.strftime("%Y-%m-%d") + "T" + aTime + ':00:00'    
      dataset = ee.ImageCollection('NOAA/NWS/RTMA').filter(ee.Filter.date(timeString));
      dataset = dataset.select('PRES','TMP','DPT','WDIR','WIND','GUST');
      collection_items = dataset.toList(max_items).getInfo()
      for item in collection_items:
          assettID = item["id"]
          image1 = ee.Image(assettID)
          dwnldUrl = image1.getDownloadUrl({
                    'region': '[[-80, 47], [-70, 47], [-70, 40], [-80, 40]]'
            })
          outputFile = 'RTMA'+datestr+'_'+aTime+'.zip'
          downPath = path2 + '/' + outputFile
          theRequest = requests.get(dwnldUrl,stream=True)
          if not theRequest.ok:
            failedList.append(outputFile)
          zipFile = open(downPath, 'wb')
          zipFile.write(theRequest.content)

print(failedList)