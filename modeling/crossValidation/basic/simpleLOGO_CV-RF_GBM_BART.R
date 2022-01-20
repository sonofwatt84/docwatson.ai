rm(list=ls(all=TRUE))

# Load Data
allData <- read.csv('../../exampleData/exampleData.csv')

# Load Libraries
library(ranger)
library(gbm)
library(BART)
library(stringr)

# Set Model Variables
predVars  <- paste0('X',str_pad(1:60,pad='0',width=2))

targetVar <- 'Y'

# Set Hyperparameters - GBM
gbmDist <- 'gaussian'

# Set Hyperparameters - BART
bartA <- 1
bartB <- 1
bartK <- 1
bartTree <- 300
bartKeep <- 700
bartBurn <- 300

# RF uses default hyperparameters

# Fix Random Seed
set.seed(1618)

# Set CV folds to be on Groups/Events
allData$fold <- allData$GRP

# Initialize Results Container
cvResults <- data.frame()

# LOGO CV For Loop....
for(aFold in unique(allData$fold)){
  print("+==================+")
  print(paste("| For Fold", aFold,"... |"))
  print("+==================+")
  # Subset Data
  pred_data <- allData[allData$fold == aFold, ]
  calib_data <- allData[!(allData$fold == aFold), ]

  # Initialize Fold's Prediction Container
  gridResults <- data.frame(gridID = pred_data$gridID,
                            eventCode = pred_data$eventCode,
                            Town = pred_data$Town,
                            Fold = pred_data$fold,
                            actuals = pred_data[targetVar],
                            BART.org = 0,
                            GBM.org = 0,
                            RF.org = 0) 
  
  # Subset Data
  trainX <- calib_data[, names(allData) %in% predVars]
  trainY <- calib_data[, names(allData) == targetVar]
  testX <- pred_data[, names(pred_data) %in% predVars]
  
  # Write Modeling Formula  
  tree.formula <- as.formula(paste0("trainY ~ ", paste(names(trainX), collapse="+")))

  # Fit BART with multiple cores - mc.wbart requires a Linux environment
  print("Fitting BART...")
  BART.fit <- mc.wbart(trainX, trainY, a= bartA, b= bartB, k= bartK, ntree = bartTree, nskip = bartBurn, ndpost = bartKeep, mc.cores = 20, nice = 15)
  # Predict for holdout....
  BART.results <- predict(BART.fit, testX)
  # Take the mean of the distribution
  BART.means <- apply(BART.results, 2, mean)
  # Round up to zero (negative values are NA here)
  BART.means[BART.means < 0] <- 0 
  # Save results
  gridResults$BART.org <- BART.means
  bartPreds <- cbind(data.frame(gridID = pred_data$gridID,countts = pred_data[targetVar]),t(BART.results))
        
  print("Fitting RF...")
  # Fit RF Model - Ranger is multithreaded by default.
  RF.fit <- ranger(x = trainX, y = trainY, save.memory = F, importance = 'impurity')
  RF.results <- predict(RF.fit, data = testX)
  RF.results <- RF.results$predictions
  #RF.results[RF.results<0] <- 0 # This isn't needed for RF - It'll never predict outside the range of the training data.
  gridResults$RF.org <- RF.results
  
  print("Fitting GBM...")
  GBM.fit<- gbm.fit(trainX, trainY, distribution = gbmDist, n.trees = 500, interaction.depth = 5, shrinkage = 0.01)
  GBM.results <- predict(GBM.fit, newdata = testX, n.trees=500)
  GBM.results[GBM.results<0] <- 0 
  gridResults$GBM.org <- GBM.results
  
  # Save all results
  cvResults <- rbind(cvResults, gridResults)
}

write.csv(cvResults, paste0("LOGOfoldCVresultsTable",Sys.Date(),".csv"), row.names = F)

###########################################################

print("All Done!!!")
