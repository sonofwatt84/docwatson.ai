# GRIB Converter

This simple script converts weather GRIB files into a more useful format for spatial analysis.  GRIB files are very commonly used for gridded weather data, but they are only somewhat compatible with spatial processing libraries like GDAL.  Important labels and metadata are usually poorly handled or completely lost.  This script automates the process of conversion to GeoTiffs. 
