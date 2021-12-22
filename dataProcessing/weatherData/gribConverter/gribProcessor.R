# Load Libraries 
library("raster")
library("rgdal")
library("gdalUtils")

# Establish File Path
gTiffPath <- "LNCA98_KWBR_201709200400.tiff"

gTiffNFO <- gdalinfo(gTiffPath)

# Import and Process Info from GeoTiff 
bandNames <- gTiffNFO[grep("GRIB_ELEMENT",gTiffNFO)]
bandNames <- gsub("GRIB_ELEMENT=","",bandNames)
bandNames <- gsub(" ","",bandNames, fixed = T)

#Load Raster Stack from GRIB
gTiffStack<-stack(gTiffPath)

#Change Band Names in Raster Stack
names(gTiffStack) <- bandNames

writeRaster(gribStack,filename = "gribTest.tif", format="GTiff", bylayer=T, suffix="names")
