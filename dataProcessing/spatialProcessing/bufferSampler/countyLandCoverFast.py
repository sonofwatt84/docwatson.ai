############################################################################
#                                                                          #
#  .-"-._,-'_`-._,-'_`-._,-'_`-._,-'_`-,_,-'_`-,_,-'_`-,_,-'_`-,_,-'_`-,   #
# (  ,-'_,-<.>-'_,-<.>-'_,-<.>-'_,-<.>-'_,-<.>-'_,-<.>-'_,-<.>-'_,-~-} ;   #
#  \ \.'_>-._`-<_>-._`-<_>-._`-<_>-._`-<_>-._`-<_>-._`-<_>-._`-._~--. \    #
#  /\ \/ ,-' `-._,-' `-._,-' `-._,-' `-._,-' `-._,-' `-._,-' `-._`./ \ \   #
# ( (`/ /                                                        `/ /.) )  #
#  \ \ / \                                                       / / \ /   #
#   \ \') )       Infrastructure Proximal Land Cover Lookup     ( (,\ \    #
#  / \ / /                For Roads By US County                 \ / \ \   #
# ( (`/ /                                                         / /.) )  #
# \ \ / \                                                       / / \ /    #
#  \ \') )                 Created:                             ( (,\ \    #
#  / \ / /                 November 27th 2017                    \ / \ \   #
# ( (`/ /                  Last Edit:                             / /.) )  #
#  \ \ / \                 December 23rd 2021                    / / \ /   #
#   \ \') )                                                     ( (,\ \    #
#  / \ / /                  By Peter Watson                      \ / \ \   #
# ( ( / /                                                         / /.) )  #
#  \ \ / \       _       _       _       _       _       _       / / \ /   #
#  ( `. `,~-._`-<,>-._`-<,>-._`-<,>-._`-<,>-._`-<,>-._`-<,>-._`-=,' ,\ \   #
#   `. `'_,-<_>-'_,-<_>-'_,-<_>-'_,-<_>-'_,-<_>-'_,-<_>-'_,-<_>-'_,"-' ;   #
#     `-' `-._,-' `-._,-' `-._,-' `-._,-' `-._,-' `-._,-' `-._,-' `-.-'    #
#                                                                          #
############################################################################

## === INITIALIZATION === ###
print("/========================================\\")
print("|  COTUS ROADSIDE LAND COVER CALCULATOR  |")
print("|            By Peter Watson             |")
print("\\========================================/")

# The Geoprocessing Libraries
from osgeo import gdal, ogr, osr
import rasterstats
# The System Libraries
import os, glob, shutil, zipfile
# The FTP Downloading Utility
import ftplib

# Set Road Buffer Distance (60m)
bufferDist = 60
# Set Number of Cores
nCore = 4 

# Establish Directory Paths
scriptDir ='./'
workDir = os.path.join(scriptDir,"temp/")
outputDir = os.path.join(scriptDir,"output/")

# Make Work/Temp Directory
if not os.path.isdir(workDir):
    os.mkdir(workDir)
if not os.path.isdir(outputDir):
    os.mkdir(outputDir)
# County Shape Path
cntyShpPath = os.path.join(scriptDir,r"data/testCounties.shp")
# NLCD Data Path #
landCoverPath = os.path.join(scriptDir,r"data/clippedLandCover.img")

# Extact NLCD Data to Temp Dir #
rastData = gdal.Open(landCoverPath)

# Load ESRI Shape Driver
shpDriver = ogr.GetDriverByName("ESRI Shapefile")

# Copy and Load County Shp File
outputFile = "testLandCoverCounts.shp"
outputPath = os.path.join(outputDir, outputFile)
# Copy File
cntyBkup = shpDriver.Open(cntyShpPath)
shpDriver.CopyDataSource(cntyBkup, outputPath)
cntyData = shpDriver.Open(outputPath, 1)
# Load County Shape/Layer
cntyLayer = cntyData.GetLayer()

# Create Landcover Type List - Manually Defined from Landcover Dataset
coverList = [11,12,21,22,23,24,31,41,42,43,51,52,71,72,81,82,90,95]
coverNames = []
# Make List of Variable Names
for code in coverList:
    coverNames.append("land" + str(code))

# Make Land Cover Fields
for var in coverNames:
    landField = ogr.FieldDefn(var, ogr.OFTString)
    cntyLayer.CreateField(landField)

# Initialize Container
theBuff = []
    
print("Environment Initialized...")
    
# For every county in shape
for county in cntyLayer:
    # Get County Variables
    cntyName = county.GetField("NAME")
    cntyCode = county.GetField("GEOID")
    ## === DOWNLOAD ROAD DATA === ###
    # Establish FTP Connection
    print("Connecting to Census FTP Site...")
    ftp = ftplib.FTP(r"ftp2.census.gov")
    ftp.login()
    ftp.cwd("/geo/tiger/TIGER2021/ROADS/")

    roadZip = r"tl_2021_%s_roads.zip" % cntyCode
    dwnldPath = os.path.join(workDir,roadZip)
    print("Downloading Road Data for %s County (GeoID %s)..." % (cntyName,cntyCode))
    newFile = open(dwnldPath, 'wb')
    ftp.retrbinary('RETR ' + roadZip, newFile.write, 1024)
    newFile.close()
    ftp.quit()

    # Unzip Road Data
    roadZip = zipfile.ZipFile(dwnldPath)
    roadZip.extractall(workDir)
    roadShp = r"tl_2021_%s_roads.shp" % cntyCode
    roadPath = os.path.join(workDir,roadShp)
    
    # Load Road Shape
    roadData = shpDriver.Open(roadPath,0)
    roadLayer = roadData.GetLayer()

    # Setup Road Transformation to EPSG:102005
    sourceCRS = roadLayer.GetSpatialRef()
    targetCRS = osr.SpatialReference()
    targetCRS.ImportFromWkt(rastData.GetProjectionRef())
    CRStrans = osr.CoordinateTransformation(sourceCRS, targetCRS)

    ## === BUFFER ROAD LINES === ###
    print("Reprojecting, Buffering, and Combining Road Features for %s County (GeoID %s)...\n" % (cntyName,cntyCode))
    # Count Road Features for Reporting Purposes
    roadCount = roadLayer.GetFeatureCount()

    # Initialize Container and Loop Counter
    bufferGeo = ogr.Geometry(ogr.wkbMultiPolygon)
    counter = 0

    for road in roadLayer:
        # Increment the Count
        counter += 1
        # Intermittently Report Status
        if counter % 50 == 0:
            print("%s Features of %s Processed....\n" % (counter,roadCount))
        # Import Geometry Information
        roadGeo = road.GetGeometryRef()
        # Reproject
        roadGeo.Transform(CRStrans)
        # Make Buffer
        bufferBlob = roadGeo.Buffer(bufferDist)
        # Add Buffer to Total Geometry
        #bufferGeo = bufferGeo.Union(bufferBlob)
        bufferGeo.AddGeometry(bufferBlob)

    print("Merging All Features...")
    bufferGeo = bufferGeo.UnionCascaded()
    
    # Convert to JSON and Calculate RasterStats
    bufferJSON = bufferGeo.ExportToJson()
    stats = rasterstats.zonal_stats(bufferJSON,landCoverPath, categorical = True)
    
    print("Writing Land Count Data...")
    print(stats)
    for type in coverList:
        varName = "land" + str(type)
        count = stats[0].get(type)
        if count is None:
            count = 0
        county.SetField(varName, count)
    
    # SAVE!!!
    cntyLayer.SetFeature(county)
    
    #Clean Up Variables
    buffFeat = None
    bufferLayer = None
    road = None
    roadLayer = None
    county = None
    
    #Delete Road Files
    searchTerm = "*%s*" % cntyCode
    fileList = glob.glob(os.path.join(workDir,searchTerm))
    [os.remove(file) for file in fileList]
    
# Remove Temporary Files
cntyLayer = None
cntyData = None

shutil.rmtree(workDir)

print("Data Processed, and Temporary Files Removed...")
print("Script Complete!")