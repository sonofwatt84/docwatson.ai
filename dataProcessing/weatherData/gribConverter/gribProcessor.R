# Load Libraries 
library("raster")
library("rgdal")
library("gdalUtils")

# Establish File Path - Can be modified for for-loops
gribPath <- "LNCA98_KWBR_201709200400.grib"

gTiffNFO <- gdalinfo(gribPath)

# Import and Process Info from GeoTiff 
bandNames <- gTiffNFO[grep("GRIB_ELEMENT",gTiffNFO)]
bandNames <- gsub("GRIB_ELEMENT=","",bandNames)
bandNames <- gsub(" ","",bandNames, fixed = T)

#Load Raster Stack from GRIB
gribStack<-stack(gribPath)

#Change Band Names in Raster Stack
names(gribStack) <- bandNames

writeRaster(gribStack,filename = "gribTest.tif", format="GTiff", bylayer=T, suffix="names")
