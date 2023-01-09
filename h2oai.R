library(h2o)
library(bigrquery)
library(ggplot2)
library(tidyverse)

billing <- "bme295-fall2020" # replace this with your project ID 

sql <- "SELECT
  weight_pounds,
  is_male,
  weight_gain_pounds,
  gestation_weeks,
  cigarette_use,
  mother_age,
  mother_race,
  father_age,
  father_race,
  ever_born
FROM
  `bigquery-public-data.samples.natality`
WHERE
  year=2005
  AND month=1
"



tb <- bq_project_query(billing, sql)
train<- bq_table_download(tb, max_results = Inf) 

#start up h2o process
h2o.init(nthreads=2)

train.hex<- as.h2o(train, destination_frame = "train.hex")  
aml <- h2o.automl(x = 2:ncol(train),
                  y=1,
                  training_frame = train.hex,
                  max_runtime_secs = 500,
                  seed = 1,
                  keep_cross_validation_predictions = TRUE)

winner<- aml@leader

#print the entire leaderboard
lb <- aml@leaderboard
print(lb, n = nrow(lb))

mygbm <- h2o.gbm(x = 2:ncol(train),
                 y=1,
                 training_frame = train.hex,
                 max_runtime_secs = 400,
                 seed = 1,
                 nfolds=5,
                 ntrees=100,
                 keep_cross_validation_predictions = TRUE)

h2o.performance(mygbm)

#Get the predictions as a single-column frame including all cv preds
cvpreds <- as.data.frame(h2o.getFrame(mygbm@model[["cross_validation_holdout_predictions_frame_id"]][["name"]]))


mypredicts<-train %>% add_column(cvpreds)

ggplot(mypredicts,aes(x=predict, y = weight_pounds))+
  geom_hex(bins=50)+
  xlim(6,9)+ylim(6,9)

ggplot(mypredicts, aes(x=weight_pounds)) + 
  geom_histogram(binwidth=0.05)

cor(mypredicts$weight_pounds,mypredicts$predict, use="pairwise.complete.obs")
h2o.varimp(mygbm)

#make the random control
control<-train
control$weight_pounds<-sample(control$weight_pounds)

control.hex<- as.h2o(train, destination_frame = "control.hex")  
mycontrol <- h2o.gbm(x = 2:ncol(control),
                 y=1,
                 training_frame = control.hex,
                 max_runtime_secs = 400,
                 seed = 2,
                 nfolds=5,
                 ntrees=100,
                 keep_cross_validation_predictions = TRUE)
h2o.performance(mycontrol)

#Get the predictions as a single-column frame including all cv preds
controlpreds <- as.data.frame(h2o.getFrame(mycontrol@model[["cross_validation_holdout_predictions_frame_id"]][["name"]]))


controltotal<-control %>% add_column(controlpreds)
cor(controltotal$weight_pounds,controltotal$predict, use="pairwise.complete.obs")
h2o.varimp(mycontrol)


#COMPARE ERRORS 
controltotal$error<-controltotal$weight_pounds-controltotal$predict
mypredicts$error<-mypredicts$weight_pounds-mypredicts$predict

ggplot() + 
  geom_density(data=mypredicts,aes(x=error, fill="Real Data"),alpha=0.5) +
  geom_density(data=controltotal, aes(x=error, fill="Control Data"), alpha=0.5)
