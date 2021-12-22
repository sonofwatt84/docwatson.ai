
#Import modules
import datetime
from datetime import timedelta
from pathlib import Path
import requests 
from urllib import request

# Enter the path of the destination folder
outputDir = r"./output/"
# Enter the start date and the end date
startDate= datetime.date(2019, 5, 16)
endDate= datetime.date(2019, 5, 17)

server1 = "https://www.ncei.noaa.gov/data/national-digital-guidance-database/access"
server2 = "https://www.ncei.noaa.gov/data/national-digital-guidance-database/access/historical/"

# Function to create the date range from given dates
def daterange(startDate, endDate):
    for n in range(int ((endDate - startDate).days + 1)):
        yield startDate + timedelta(n)

# List of the 24 hrs in a day
theTimes = ["%02d" %i for i in list(range(0,24,1))] 

# Function for Downloading
def rtmaDownloader(readPath,writePath):
        filename = Path(writePath)
        url1=server1 + '/' + readPath
        url2=server2 + '/' + readPath
        # Try First Server
        rFile = requests.get(url1,stream=True)
        if not rFile.ok:
          # If first server doesn't work, try second
          rFile = requests.get(url2,stream=True)
        if not rFile.ok:
          # If neither server works, save the failure
          failed_list.append(filename)
          return
        grib_file = open(filename, 'wb')
        grib_file.write(rFile.content)
    
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
        LEIfileName= str(folderPath)+'/LEIA98_KWBR_'+ str(datestr)+str(aTime)+'00'
        LTIfileName= str(folderPath)+'/LTIA98_KWBR_'+ str(datestr)+str(aTime)+'00'
        LNIfileName= str(folderPath)+'/LNIA98_KWBR_'+ str(datestr)+str(aTime)+'00'
        LRIfileName= str(folderPath)+'/LRIA98_KWBR_'+ str(datestr)+str(aTime)+'00'
        LPIfileName= str(folderPath)+'/LPIA98_KWBR_'+ str(datestr)+str(aTime)+'00'
        
        LEItarget= path2+ '/rain'+str(datestr)+str(aTime)+'.grib2'
        LTItarget= path2+ '/temp'+str(datestr)+str(aTime)+'.grib2'
        LNItarget= path2+ '/wind'+str(datestr)+str(aTime)+'.grib2'
        LRItarget= path2+ '/dewT'+str(datestr)+str(aTime)+'.grib2'
        LPItarget= path2+ '/pres'+str(datestr)+str(aTime)+'.grib2'
        
        # Create the file URL
        failed_list=[]
        
        rtmaDownloader(LEIfileName,LEItarget)
        rtmaDownloader(LTIfileName,LTItarget)
        rtmaDownloader(LNIfileName,LNItarget)
        rtmaDownloader(LRIfileName,LRItarget)
        rtmaDownloader(LPIfileName,LPItarget)

    if(len(failed_list)>0):
        print("Failed",failed_list)