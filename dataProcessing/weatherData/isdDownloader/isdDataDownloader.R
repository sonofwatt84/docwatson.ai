##=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=##
##  -------------------------------  ##
##  Weather Station Data Downloader  ##
##  -------------------------------  ##
##                                   ##
##  This script downloads chunks of  ##
##  ISD weather station data from    ##
##  NOAA's archive.  Use 'theYears'  ##
##  and 'domainFile' to  control the ##
##  time and place of the stations.  ##
##                                   ##
##=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=##

rm(list=ls(all=TRUE))

library("rgdal")
library("rgeos")
library("stringr")

# Years of Interest
theYears <- c(2019:2020)
# Domain File - Defines the spatial extent of the stations downloaded
domainFile <- 'data/ctTowns.shp'
# Output Directory
outDir <- "output/wthr"

# Load Domain #
domainArea <- readOGR(domainFile, verbose=F)
#Add 10km to domainArea
domainArea <- spTransform(domainArea, CRS("+init=epsg:26956")) # This CRS is optimized for Connecticut, USA. 
domainArea <- gBuffer(domainArea, width=10000)
#Reproject to Standard Unprojected CRS
domainArea <- spTransform(domainArea, CRS("+init=epsg:4326"))

#--------------------------------#
# Download Weather ISD Meta Data #
#--------------------------------#
# Station List Path
stationHistPath <- file.path(outDir,paste0("isd-history",Sys.Date(),".csv"))
# Station Inventory Path
stationInvnPath <- file.path(outDir,paste0("isd-inventory",Sys.Date(),".csv"))

# Get Up-to-date Station List and Inventory
print("Downloading Weather Station List...")
download.file("https://www1.ncdc.noaa.gov/pub/data/noaa/isd-history.csv", stationHistPath,method = "auto", quiet = F)

print("Downloading Weather Data Inventory...")
download.file("https://www1.ncdc.noaa.gov/pub/data/noaa/isd-inventory.csv", stationInvnPath,method = "auto",quiet = F)
  
#Load Station Data#
stationList <- read.csv(stationHistPath)
stationInv <- read.csv(stationInvnPath)
# Restrict Stations to Ones that have a ICAO code
stationList <- stationList[(stationList$ICAO != ''),]
# Restrict Stations to Ones that have a WBAN code
stationList <- stationList[(stationList$WBAN != '99999'),]
# Restrict Stations to Ones only in Domain
stationPnts <- SpatialPoints(stationList[c("LON","LAT")], proj4string = CRS("+init=epsg:4326"))
stationList <- stationList[gContains(domainArea,stationPnts, byid = T),]
# Make Station ID Codes
stationList$WBAN<-str_pad(stationList$WBAN, 5, pad = "0")
stationList$ID<-paste0(stationList$USAF,stationList$WBAN)
stationInv$WBAN<-str_pad(stationInv$WBAN, 5, pad = "0")
stationInv$ID<-paste0(stationInv$USAF,stationInv$WBAN)
# Reduce Inventory List to Only Available Ones
stationInv <- stationInv[stationInv$ID %in% stationList$ID,]

#-----------------------#
# Download Weather Data #
#-----------------------#

# For Every Year in the List
for(year in theYears){
  # Get the Stations that Have Data for that Year
  yearStationList <- stationInv$ID[stationInv$YEAR == year]
  # For that list of stations
  for (station in yearStationList){
    # Download Data
    weatherFilePath <- file.path(outDir,year,paste0(station,".csv"))
    yearDir<-file.path(outDir,year)
    if (!(dir.exists(yearDir))){dir.create(yearDir)}
    if (!(file.exists(weatherFilePath))){
      site<-"https://www.ncei.noaa.gov/data/global-hourly/access/"
      loc <-file.path(year,paste0(station,".csv"))
      tempPath <- paste0(weatherFilePath,".dwnld")
      download.file(paste0(site,loc),tempPath, method = "auto", quiet = T) # Verbose Output can slow script
      file.rename(tempPath,weatherFilePath)
      print(paste("Downloaded", weatherFilePath,". . ."))
    }
  }
}

## Clean-Up Messy Files ##
allFiles <- paste0(outDir,(dir(outDir,recursive = T)))
badFiles <- allFiles[grepl(".dwnld",allFiles)]
file.remove(badFiles)

## Remove Station Metadata Files ##
file.remove(c(stationHistPath,stationInvnPath))