# CV Script for BART model

# Load libraries
library(BART)
library(snow)
library(parallel)

rm(list=ls(all=TRUE))
# Load Data
allData <- read.csv('../../exampleData/exampleData.csv')

# Specify Label based on Current Date
theDate <- Sys.Date()
theLabel<-paste0("bartCVmpi_",theDate)
# Create Output Directory
outDir <- 'output'
if(!dir.exists(outDir)){dir.create(outDir)}
outDir <- file.path(outDir,'BARTmpiCV')
if(!dir.exists(outDir)){dir.create(outDir)}
outDir <- file.path(outDir,theLabel)
if(!dir.exists(outDir)){dir.create(outDir)}

# Specify CV Folds - Groups/Storms
theStorms <- levels(allData$GRP)
eventCount <- length(theStorms)
allData$fold <- allData$GRP
doneFiles <- dir(outDir)
doneFiles <- gsub('.csv','',doneFiles)
doneSlices <- strsplit(doneFiles,'-')
doneSlices <- sapply(doneSlices,function(x) x[2])

###############################################################
### Filter out Done Folds in case of a restart... #############
###############################################################
theStorms <- theStorms [theStorms != doneSlices]

nNodes<-as.numeric(Sys.getenv()["SLURM_NTASKS"])
nNodes<-nNodes - 1


# Set Model Variables
predVars  <- paste0('X',str_pad(1:60,pad='0',width=2))

targetVar <- 'Y'

# The modeling function...
bartTest <- function(theSlice){
  aTest <- 1
  kTest <- 1
  nTree <- 300
  keeper<- 700
  burnIn<- 300
  bTest <- 1 
  print(paste('Training BART for',theSlice,"..."))
  trainX <- allData[theSlice != allData$fold, predVars]
  trainY <- allData[theSlice != allData$fold, targetVar]
  testX  <- allData[theSlice == allData$fold, predVars]
  testY  <- allData[theSlice == allData$fold, targetVar]
  bartModel <- wbart(trainX, trainY, a= bartA, b= bartB, k= bartK, ntree = bartTree, nskip = bartBurn, ndpost = bartKeep)
  modelPreds <- predict(bartModel, testX)
  modelPreds <- apply(modelPreds,2,mean)
  modelPreds[modelPreds<0] <- 0
  
  gridResults <- data.frame(groupCode = allData[theSlice == allData$fold, 'GRP'],
                            actuals = testY,
                            BART.org = modelPreds) 
  
  resultFile <- file.path(outDir,paste0(theLabel,'-',theSlice,'.csv'))
  print(paste('Writing Output for',theSlice,'...'))
  write.csv(gridResults,resultFile,row.names = F)
}

print(paste(nNodes,'Nodes Available...')) 
# Make Cluster
cl <- makeMPIcluster(nNodes)
# Load Libraries in Cluster
clusterEvalQ(cl, library(BART))
# Load Variables in Cluster
clusterObj = c('theLabel','allData','predVars','targetVar')
clusterExport(cl, clusterObj)
# Run CV Functions on Cluster
clusterApply(cl,theStorms,bartTest)
# Stop Cluster
stopCluster(cl)
# Done
print('🕴️~~~  ALL DONE  ~~~🕴️')
