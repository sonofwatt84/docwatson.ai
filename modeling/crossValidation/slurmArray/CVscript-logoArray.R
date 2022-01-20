rm(list=ls(all=TRUE))

rm(list=ls(all=TRUE))
# Load Data
allData <- read.csv('../../exampleData/exampleData.csv')
library(ranger)
library(gbm)
library(BART)
library(UBL)

# Define and Create Output Directory
outDir <- 'output'
if(!dir.exists(outDir)){dir.create(outDir)}

# Set Model Variables
predVars  <- paste0('X',str_pad(1:60,pad='0',width=2))

targetVar <- 'Y'

## Specify Modeling Hyperparameters

gbmDist <- 'gaussian'
gbmTree <- 1111
gbmIntd <- 22
gbmShrk <- 0.0333

# Pull-In SLURM parameters passed to script
args = commandArgs(trailingOnly=TRUE)
theEvent <- as.numeric(args[1])
# Pull-In Core Allocation from Sys ENV
nCores<-as.numeric(Sys.getenv()["SLURM_NTASKS"])

# Specify CV Folds
allData$theSlices <- allData$GRP

# Fix Random Seed
set.seed(1618)

theStorms <- unique(allData$theSlices)

# Define which fold
aFold <- theStorms[theEvent]
print("+==================+")
print(paste("| For Fold", aFold,"... |"))
print("+==================+")
# Subset Data
pred_data <- allData[allData$eventCode == aFold, ]
calib_data <- allData[!(allData$eventCode == aFold), ]

# Initialize pred Container
gridResults <- data.frame(gridID = pred_data$gridID,
                          eventCode = pred_data$eventCode,
                          Town = pred_data$Town,
                          actuals = pred_data[targetVar],
                          GBM.org = 0)


# Subset Data
trainX <- calib_data[,predVars]
trainY <- calib_data[,targetVar]
testX <- pred_data[,predVars]

print("Fitting GBM...")
GBM.fit<- gbm.fit(trainX, trainY, distribution = gbmDist, n.trees = gbmTree, interaction.depth = gbmIntd, shrinkage = gbmShrk)
GBM.results <- predict(GBM.fit, newdata = testX, n.trees=gbmTree)
GBM.results <- GBM.results
GBM.results[GBM.results<0] <- 0 
gridResults$GBM.org <- GBM.results

gridFile <- file.path(outDir,paste0('arrayCV-event',aFold,'.csv'))
print(paste('Writing Output for',aFold,'...'))
write.csv(gridResults,gridFile,row.names = F)
