library(fftw)
library(seewave)
library(tuneR)
library(randomForest)

humanFrequency <- 280

analyzeWav <- function(file, start = 0, end = Inf) {
  wave <- file
  tuneWave <- readWave(file.path(getwd(), wave), from = start, to = end, units = "seconds")
  waveSpec <- spec(tuneWave, f = tuneWave@samp.rate, plot = F)
  analysis <- specprop(waveSpec, f = tuneWave@samp.rate, flim = c(0, humanFrequency / 1000), plot = F)
  
  meanfreq <- analysis$mean / 1000
  sd <- analysis$sd / 1000
  median <- analysis$median / 1000
  Q25 <- analysis$Q25 / 1000
  Q75 <- analysis$Q75 / 1000
  IQR <- analysis$IQR / 1000
  skew <- analysis$skewness
  kurt <- analysis$kurtosis
  sp.ent <- analysis$sh
  sfm <- analysis$sfm
  mode <- analysis$mode / 1000
  centroid <- analysis$cent / 1000
  
  fundamental <- fund(tuneWave, f = tuneWave@samp.rate, ovlp = 50, threshold = 5, wl = 2048,
                      ylim = c(0, humanFrequency / 1000), fmax = humanFrequency, plot = F)
  
  meanfun <- mean(fundamental[, 'y'], na.rm = T)
  minfun <- min(fundamental[, 'y'], na.rm = T)
  maxfun <- max(fundamental[, 'y'], na.rm = T)
  
  b <- c(0, 22)
  dom <- dfreq(tuneWave, f = tuneWave@samp.rate, wl = 2048, ylim = c(0, humanFrequency / 1000),
               ovlp = 0, threshold = 5, bandpass = b * 1000, fftw = T, plot = F)[, 2]
  
  meandom <- mean(dom, na.rm = TRUE)
  mindom <- min(dom, na.rm = TRUE)
  maxdom <- max(dom, na.rm = TRUE)
  dfrange <- (maxdom - mindom)
  duration <- (end - start)
  
  changes <- vector()
  for(d in which(!is.na(dom))) {
    change <- abs(dom[d] - dom[d + 1])
    changes <- append(changes, change)
  }
  if(mindom == maxdom) modindx <- 0 else modindx <- mean(changes, na.rm = T) / dfrange
  
  obj <- data.frame(duration, meanfreq, sd, median, Q25, Q75, IQR, skew, kurt, sp.ent, sfm, mode, 
                    centroid, meanfun, minfun, maxfun, meandom, mindom, maxdom, dfrange, modindx)
  names(obj) <- c("duration", "meanfreq", "sd", "median", "Q25", "Q75", "IQR", "skew", "kurt", "sp.ent", 
                  "sfm","mode", "centroid", "meanfun", "minfun", "maxfun", "meandom", "mindom", "maxdom",
                  "dfrange", "modindx")
  obj
}

path <- commandArgs(trailingOnly = T)
analyzedVoice <- analyzeWav(path)
#model.forest <- randomForest(label ~ ., data = file)
modelPath <- 'model.forest.rds'
file.path(getwd(), modelPath)
model.forest <- readRDS('model.forest.rds')
prediction <- predict(model.forest, analyzedVoice)
print(prediction)
cat(prediction, file = 'prediction.txt')