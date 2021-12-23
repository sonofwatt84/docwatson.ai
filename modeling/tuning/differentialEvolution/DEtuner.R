rm(list=ls(all=TRUE))

allData <- read.csv("../../exampleData/exampleData.csv")

# Specify Label
theDate <- Sys.Date()
theLabel<-paste0("DEsearch_",theDate)
theStorms <- levels(allData$eventCode)
eventCount <- length(theStorms)

nSlice <- 4
theSlices <- 1:nSlice
allData$theSlices <- sample(rep_len(theSlices, nrow(allData)))

# Load libraries
library(gbm)
library(snow)
library(parallel)
library(DEoptim)
library(Metrics)

nNodes<-as.numeric(Sys.getenv()["SLURM_NTASKS"])
nNodes<-nNodes - 1

print(paste(nNodes,'Nodes Available...')) 
cl <- makeMPIcluster(nNodes)
# Load Libraries in Cluster
clusterEvalQ(cl, library(gbm))
clusterEvalQ(cl, library(Metrics))

predVars <- c('X01','X02','X03','X04','X05','X06','X07','X08','X09','X10','X11','X12')

targetVar <- 'Y'


# Clean & Normalize
allData <- allData[complete.cases(allData[predVars]),]
allData[predVars] <- sapply(allData[predVars], scale)

gbmTest <- function(theSlice,x){
  nTree <- as.numeric(x[1])
  intDepth<- as.numeric(x[2])
  shrink <- as.numeric(x[3])
  minNode <- as.numeric(x[4])
  print(paste0('Testing GBM for Slice ',theSlice," with n.trees: ",nTree,", interaction.depth: ",intDepth,", shrinkage: ", shrink," , n.minobsinnode: ", minNode))
  trainX <- allData[theSlice != allData$theSlices, predVars]
  trainY <- allData[theSlice != allData$theSlices, targetVar]
  testX  <- allData[theSlice == allData$theSlices, predVars]
  testY  <- allData[theSlice == allData$theSlices, targetVar]
  gbmModel<- gbm.fit(trainX, trainY, distribution = 'gaussian', n.trees = nTree, interaction.depth = intDepth, shrinkage = shrink, n.minobsinnode = minNode, verbose=FALSE)
  modelPreds <- predict(gbmModel, newdata = testX, n.trees=nTree)
  modelPreds[modelPreds<0] <- 0 
  RMSLE   <- rmsle(testY, modelPreds)
  return(RMSLE)
}

gbmCVtest <- function(hyperParameters){ #Takes: nTree, intDepth, shrink, minNode
  theErrors <- c()
  for (aSlice in theSlices){
    theErrors <- c(theErrors,gbmTest(aSlice, hyperParameters))
  }
  return(mean(theErrors))
}

gbmLimits  <- list(n.trees = c(500,2000), 
                   interaction.depth = c(3,49), 
                   shrinkage = c(0.001,0.1), 
                   n.minobsinnode = c(20,100))

deKontrol <- DEoptim.control(VTR = 0,           # Value to be Reached: Causes early stopping
                             NP = nNodes,       # Populuation: Should be >10x the number of hyperparameters
                             itermax = 100,     # Max Iterations: Default is 200
                             CR = 0.5,          # Crossover Probability
                             steptol = 5,       # Number of steps until early stopping is applied
                             storepopfreq =  1, # Save all populations
                             parallelType =  1, # Parallelize!! 
                             cluster = cl, #
                             parVar = c('theSlices','gbmTest','allData','predVars','targetVar'),
                             packages = c('gbm','Metrics'))

print('DE Optimize!!!!')
gbmDEsearch <- DEoptim(fn = gbmCVtest, 
                       lower = sapply(gbmLimits, function(item) item[1]),
                       upper = sapply(gbmLimits, function(item) item[2]),
                       control = deKontrol)

stopCluster(cl)

outFolder <- paste0("output/",theLabel,"/")
if (!(dir.exists(outFolder))) dir.create(outFolder)
save(gbmDEsearch,file = paste0(outFolder,theLabel,'.Rout'))
