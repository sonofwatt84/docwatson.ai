#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Nov 28 09:39:48 2017
@author: sonofwatt
"""

# The Libraries
from osgeo import ogr, osr
import os

outputDir ='./output'
inputDir ='./data'

print("===================")
print("= Measuring Roads =")
print("===================")

# Name inputs/outputs
gridFile = "fairfieldGrid.geojson"
lineFile = "tl_2021_09001_roads.shp"
outputBase = "lineGrid"
outputFile = outputBase + ".shp"

gridPath = os.path.join(inputDir,gridFile)
linePath = os.path.join(inputDir,lineFile)
outputPath = os.path.join(outputDir, outputFile)
    
# Load ESRI Shape Driver
shpDriver = ogr.GetDriverByName("ESRI Shapefile")
# Load GeoJSON Driver
gjsDriver = ogr.GetDriverByName("GeoJSON")
    
# Copy/Open Grid
gridIn = gjsDriver.Open(gridPath)
# Copy File
shpDriver.CopyDataSource(gridIn, outputPath)
# Open Grid
gridData = shpDriver.Open(outputPath, 1)
# Load County Shape/Layer
gridLayer = gridData.GetLayer()
    
# Setup Line Transform
sourceCRS = gridLayer.GetSpatialRef()
targetCRS = osr.SpatialReference()
targetCRS.ImportFromEPSG(26918) # Optimized for CT
CRStrans = osr.CoordinateTransformation(sourceCRS, targetCRS)
    
######################################
###                                ###
###    Road Length by Grid Cell    ###
###                                ###
######################################
# New Field in Shape
gridLayer.CreateField(ogr.FieldDefn("roadLng", ogr.OFTReal))
# Open Lines
lineData = shpDriver.Open(linePath, 0)
# Load County Shape/Layer
lineLayer = lineData.GetLayer()
    
for cell in gridLayer:
  print("Total Road Length for Grid Cell %s"% cell.GetField("gridID"))
  # Get Grid Geometery
  cellGeo = cell.GetGeometryRef()
  cellGeo.Transform(CRStrans)
  # Get Line Geometery
  cellLineGeo = ogr.Geometry(ogr.wkbLineString)
  for line in lineLayer:
    lineGeo = line.GetGeometryRef()
    lineGeo.Transform(CRStrans)
    cellLine = lineGeo.Intersection(cellGeo)
    cellLineGeo = cellLineGeo.Union(cellLine)
  cellLength = cellLineGeo.Length()
  print(cellLength)
  cell.SetField("roadLng",cellLength)
  # SAVE!!!
  gridLayer.SetFeature(cell)
  #Reset Line Layer
  lineLayer.ResetReading()
gridLayer.ResetReading()

# Close and Save    
gridLayer = None
gridData = None
ettLayer = None
ettData = None
lineData = None
lineLayer = None
    
targetCRS.MorphToESRI()
outputPath = os.path.join(outputDir, outputBase + '.prj')
prjFile = open(outputPath, 'w+')
prjFile.write(targetCRS.ExportToWkt())
prjFile.close()
    
print(" - - - All Done!!! - - - ")
    
