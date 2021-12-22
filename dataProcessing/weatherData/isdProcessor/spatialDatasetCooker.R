##=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=##
##  -------------------------------  ##
##        ISD Data Processor         ##
##  -------------------------------  ##
##                                   ##
##  This script processes available  ##
##  ISD weather station data to make ##
##  time series for each station. It ##
##  saves weather data as a CSV, but ##
##  save weather stations locations  ##
##  as a GeoJSON.                    ##
##                                   ##
##=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=##

rm(list=ls(all=TRUE))

# Load Libraries
library('raster')
library('rgdal')
library('rgeos')
library('zoo')
library('circular')

# ISD Data location
wthrDir  <- "../isdDownloader/output/wthr"
# Output Directory
outDir   <- "./output"
theYears <- dir(wthrDir)
# Make sure they're directories
theYears <- theYears[dir.exists(file.path(wthrDir,theYears))]

#------------------#
# Process ISD Data #
#------------------#
print("Generating METAR Station List...")
stationFrame <- data.frame()

# This method is not robust to junk files in the weather data directory tree.  Keep it tidy.
for (aYear in theYears){ 
  fileList <- dir(file.path(wthrDir,aYear))
  stationList <- gsub(".csv","",fileList)
  fileList <- file.path(wthrDir,aYear,fileList)

  for (i in 1:length(stationList)){
    aStation <- stationList[i]
    print(paste("Processing", aYear, "data for Station",aStation,". . ."))
    weatherData <-read.csv(fileList[i])
    # Work with Only FM-15/16 Reports
    weatherData <-weatherData[grepl("FM-15",as.character(weatherData$REPORT_TYPE)) | grepl("FM-16",as.character(weatherData$REPORT_TYPE)),] 
    # Skip station if no FM-15/16 Reports are present
    if (nrow(weatherData) == 0){
      next
    }
    # Save Station Information
    stationFrame <- rbind(stationFrame,weatherData[1,c('STATION','LONGITUDE','LATITUDE','ELEVATION')])
    
    #Adjust Time: Zero-out Minutes/Seconds
    weatherData$DATE <- as.POSIXct(weatherData$DATE, format="%Y-%m-%dT%H:%M:%S",tz="UTC")
    weatherData$dateTime <- as.POSIXct(cut(weatherData$DATE,"hour"),tz="UTC")
  
    # Process Wind Data
    theWinds <- strsplit(as.character(weatherData$WND),split=",")
    windDir  <- unlist(lapply(theWinds, '[[', 1))
    theWinds <- unlist(lapply(theWinds, '[[', 4))
    windDir[windDir == '999']  <- NA
    theWinds[theWinds == '9999'] <- NA
    theWinds <- as.numeric(theWinds)/10
    weatherData$WIND <- theWinds
    weatherData$WDIR <- circular(as.numeric(windDir), units = 'degrees')
    # Process Gust Data if present - the NA are because gust are only reported sometimes.  
    if (!(is.null(weatherData$OC1))){
      theGusts <- as.character(weatherData$OC1)
      theGusts[theGusts == ""] <- "9999,9"
      theGusts <- strsplit(theGusts,split=",")
      theGusts <- unlist(lapply(theGusts, '[[', 1))
      theGusts[theGusts == '9999'] <- NA
      theGusts <- as.numeric(theGusts)/10
      weatherData$GUST <- theGusts
    }else{
      weatherData$GUST <- NA
    }
    # Process Temp Data
    theTemps <- strsplit(as.character(weatherData$TMP),split=",")
    theTemps <- unlist(lapply(theTemps, '[[', 1))
    theTemps[theTemps == '+9999'] <- NA
    theTemps <- as.numeric(theTemps)/10
    weatherData$TEMP <- theTemps
    # Process Dew Point Data
    theDews <- strsplit(as.character(weatherData$DEW),split=",")
    theDews <- unlist(lapply(theDews, '[[', 1))
    theDews[theDews == '+9999'] <- NA
    theDews <- as.numeric(theDews)/10
    weatherData$DEWS <- theDews

    # Process Pressure Data - SLP isn't reported in FM-16 reports, so there are many NAs. Requires special handling.
    theHpas <- strsplit(as.character(weatherData$SLP),split=",")
    theHpas <- unlist(lapply(theHpas, '[[', 1))
    theHpas[theHpas == '99999'] <- NA
    theHpas <- as.numeric(theHpas)/10
    weatherData$PRES <- theHpas
  
    # Calculate Specific Humidity
    theEs = 6.112*exp((17.67*weatherData$DEWS)/(weatherData$DEWS + 243.5))
    SPEC_H = (0.622 * theEs)/(weatherData$PRES - (0.378 * theEs))
    weatherData$SPFH <- SPEC_H
  
    # Scale Pressure Units
    weatherData$PRES <- theHpas * 100
  
  # Process Precip Data
  if (!(is.null(weatherData$AA1))){
    thePrecip <- strsplit(as.character(weatherData$AA1),split=",")
    thePrecip <- unlist(lapply(thePrecip, '[', 2))
    thePrecip[is.na(thePrecip)] <- 0
    thePrecip[thePrecip == '9999'] <- NA
    thePrecip <- as.numeric(thePrecip)/10
    weatherData$PREC <- thePrecip
  }else{
    weatherData$PREC <- NA
  }
  # Aggregate to hourly averages, dropping NAs
  aggedData <- aggregate(weatherData[c('GUST','WIND','WDIR','TEMP','DEWS','PRES','PREC','SPFH')], list(weatherData$dateTime), FUN = mean, na.rm =T)
  # Save processed data
  yearDir <- file.path(outDir,aYear)
  outPath <- file.path(yearDir,paste0(aStation,'.csv'))
  if (!(dir.exists(yearDir))){dir.create(yearDir)}
  write.csv(aggedData,outPath,row.names = F)
  }
}
stationFrame <- stationFrame[!duplicated(stationFrame),]

# Make SpatialPointsDataFrame of ISD Station Data
stationPoints <- SpatialPointsDataFrame(stationFrame[c('LONGITUDE','LATITUDE')],stationFrame, proj4string = CRS("+init=epsg:4326"))

writeOGR(stationPoints, file.path(outDir,"isdStations.geojson"), "GeoJSON", driver="GeoJSON", overwrite_layer = T)

print(' - - All Done! - - ')