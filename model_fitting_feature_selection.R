# Model fitting on the standardized data for feature selection
# have already done initial feature selection with lasso in Python 


# read in the standardized data
train<- read.csv('Fixed_log_standardized_train.csv')
test <- read.csv('Fixed_log_stadardaized_test.csv')

#be sure the response & other needed features are a categorical 
is.factor(train$women_involved)
train$women_involved<- factor(train$women_involved)
is.factor(train$women_involved)
test$women_involved<- factor(test$women_involved)

train$bea_region<- factor(train$bea_region)
test$bea_region<- factor(test$bea_region)

train$any_R_uni_involved<- factor(train$any_R_uni_involved)
test$any_R_uni_involved<- factor(test$any_R_uni_involved)

#look at the variable names
names(train)


###################################################################################
# run first model with those posibly being used 
results<-glm(women_involved ~ any_R_uni_involved+ Manufacturing 
             + Health_Care_Social_Assistance #+ Accommodation_Food_Services
             + Information + Educational_Services
             + Professional_Scientific_and_Technical_Services,
             family = 'binomial', data = train)


#lok at results -> p-values 
summary(results)

#do they contain zero? 
confint(results, level= 0.95)

#load in the library for Variable INflation Facators (VIFS)
library(faraway)
#look at VIFs for firt model 
vif(results)
#check coorlations to remove mulitcolinariety-> kept profession and scientific 
# because highest VIF -> got rid of info and health care

#large VIFs so need to check cooelations
# bind the predictors to lool at just their coorlation matrix
predictors<-cbind(train$any_R_uni_involved, train$Manufacturing, 
                  #train$Health_Care_Social_Assistance,
                  #train$Information, 
                  train$Educational_Services, 
                  train$Professional_Scientific_and_Technical_Services)
cor(predictors)


# let's look at the ROCR curve 
library(ROCR)
#setup for ROC
#preds holds all estimated probabilities of survival 
preds<- predict(results, newdata=test, type= 'response')
# numbers for classificiation table 
rates<- prediction(preds, test$women_involved)
#stores true positive and false positive rates for all possible values of threshold [0,1]
roc_results<- performance(rates, measure='tpr', x.measure='fpr')
#plot ROC & line containing (0,0) & (1,1)
plot(roc_results)
lines(x=c(0,1), y=c(0,1), col='red')
#if plot in the upper left had above the diagonal line the performs better than
#random guessing

#1D AUC area under the curve
auc<-performance(rates, measure = "auc")
auc@y.values
#0.565
#As you can see, the result is a scalar number, the area under the curve (AUC). 
#This number ranges from (0) to (1) with (1) indicating 100% specificity and 
#100% sensitivity.

#1E confusion matrix
table(test$women_involved, preds > 0.235)





results_region<-glm(women_involved ~ any_R_uni_involved+ Manufacturing 
             + Health_Care_Social_Assistance
             + Information + Educational_Services 
             + Professional_Scientific_and_Technical_Services
             + bea_region,
             family = 'binomial', data = train)

summary(results_region)

#preds holds all estimated probabilities of survival 
preds_r<- predict(results_region, newdata=test, type= 'response')
# numbers for classificiation table 
rates_r<- prediction(preds_r, test$women_involved)
#stores true positive and false positive rates for all possible values of threshold [0,1]
roc_results_r<- performance(rates_r, measure='tpr', x.measure='fpr')
#plot ROC & line containing (0,0) & (1,1)
plot(roc_results_r)
lines(x=c(0,1), y=c(0,1), col='red')
#if plot in the upper left had above the diagonal line the performs better than
#random guessing

#1D AUC area under the curve
auc<-performance(rates_r, measure = "auc")
auc@y.values
#0.565
#As you can see, the result is a scalar number, the area under the curve (AUC). 
#This number ranges from (0) to (1) with (1) indicating 100% specificity and 
#100% sensitivity.

#1E confusion matrix
table(test$women_involved, preds > 0.235)


# look at reduced model 
#now with low VIF's
results2<-glm(women_involved ~ any_R_uni_involved+ Manufacturing 
             + Educational_Services 
             + Health_Care_Social_Assistance
             + Information, 
             family = 'binomial', data = train)
#all predictors show significant
summary(results2)

#look at confidence intervals
# one of the intervals include zero.... good news!
confint(results2, level= 0.95)

#library(faraway)
#verify the VIF's are < 10 so predictors are not collilated (multicollinearity)
vif(results2)
# all < 10

#setup for ROC
#preds holds all estimated probabilities of survival 
preds2<- predict(results2, newdata=test, type= 'response')
# numbers for classificiation table 
rates2<- prediction(preds2, test$women_involved)
#stores true positive and false positive rates for all possible values of threshold [0,1]
roc_results2<- performance(rates2, measure='tpr', x.measure='fpr')
#plot ROC & line containing (0,0) & (1,1)
plot(roc_results2)
lines(x=c(0,1), y=c(0,1), col='red')
#if plot in the upper left had above the diagonal line the performs better than
#random guessing

#1D AUC area under the curve
auc<-performance(rates2, measure = "auc")
auc@y.values
#0.5643
#As you can see, the result is a scalar number, the area under the curve (AUC). 
#This number ranges from (0) to (1) with (1) indicating 100% specificity and 
#100% sensitivity.

#1E confusion matrix
table(test$women_involved, preds2 > 0.235)





#now with region 

results_r2<-glm(women_involved ~ any_R_uni_involved+ Manufacturing 
              + Educational_Services 
              + Health_Care_Social_Assistance
              + Information + bea_region,
              family = 'binomial', data = train)
#all predictors show significant
summary(results_r2)

#is the model useful??
# are all coefficients = 0 ?
#testing all coefficients, use Delta G^2 test statistic
#df = 1213266(df of null deviance) - 1213254(res deviance for full) = 12
#H0: all Bs  = 0 (not useful)
#HA: at least one B non zero (useful)
#want areas to the right so subtract from 1
1-pchisq(results_r2$null.deviance-results_r2$deviance,12)
#p = 0 , p < 0.05, reject the null- data supports that at least one 
#of the coefficients is nonzero

#look at confidence intervals
# one of the intervals include zero.... 
confint(results_r2, level= 0.95)

#library(faraway)
#verify the VIF's are < 10 so predictors are not collilated (multicollinearity)
vif(results_r2)
# all < 10

#setup for ROC
#preds holds all estimated probabilities of survival 
preds_r2<- predict(results_r2, newdata=test, type= 'response')
# numbers for classificiation table 
rates_r2<- prediction(preds_r2, test$women_involved)
#stores true positive and false positive rates for all possible values of threshold [0,1]
roc_results_r2<- performance(rates_r2, measure='tpr', x.measure='fpr')
#plot ROC & line containing (0,0) & (1,1)
plot(roc_results_r2)
lines(x=c(0,1), y=c(0,1), col='red')
#if plot in the upper left had above the diagonal line the performs better than
#random guessing

#1D AUC area under the curve
auc<-performance(rates_r2, measure = "auc")
auc@y.values
#0.5783
#As you can see, the result is a scalar number, the area under the curve (AUC). 
#This number ranges from (0) to (1) with (1) indicating 100% specificity and 
#100% sensitivity.

#1E confusion matrix
table(test$women_involved, preds_r2 > 0.235)

(test$women_involved = preds_r2)







# now build model on non standardized and see what happens? 

train_raw<- read.csv('Fixed_log_RAW_train.csv')
test_raw <- read.csv('Fixed_log_RAW_test.csv')

#be sure the response & other needed features are a categorical 
train_raw$women_involved<- factor(train_raw$women_involved)
test_raw$women_involved<- factor(test_raw$women_involved)

train_raw$bea_region<- factor(train_raw$bea_region)
test_raw$bea_region<- factor(test_raw$bea_region)

train_raw$any_R_uni_involved<- factor(train_raw$any_R_uni_involved)
test_raw$any_R_uni_involved<- factor(test_raw$any_R_uni_involved)


#now build and assess on raw data
model<-glm(women_involved ~ any_R_uni_involved+ Manufacturing 
                + Educational_Services 
                + Health_Care_Social_Assistance
                + Information + bea_region,
                family = 'binomial', data = train_raw)
#all predictors show significant
summary(model)

#look at confidence intervals
# one of the intervals include zero.... good news!
confint(model, level= 0.95)

#library(faraway)
#verify the VIF's are < 10 so predictors are not collilated (multicollinearity)
vif(model)
# all < 10
# levels(train_raw$bea_region)
#far west is the comparicon level 


#setup for ROC
#preds holds all estimated probabilities of survival 
preds_m<- predict(model, newdata=test, type= 'response')
# numbers for classificiation table 
rates_m<- prediction(preds_m, test_raw$women_involved)
#stores true positive and false positive rates for all possible values of threshold [0,1]
roc_results_m<- performance(rates_m, measure='tpr', x.measure='fpr')
#1D AUC area under the curve
auc<-performance(rates_m, measure = "auc")
auc@y.values

#0.5763
#As you can see, the result is a scalar number, the area under the curve (AUC). 
#This number ranges from (0) to (1) with (1) indicating 100% specificity and 
#100% sensitivity.

#plot ROC & line containing (0,0) & (1,1)
plot(roc_results_m)
lines(x=c(0,1), y=c(0,1), col='red')
title(main ='ROC Curve for Logistic Regresion')
mtext(auc@y.values)
#if plot in the upper left had above the diagonal line the performs better than
#random guessing



#1E confusion matrix
table(test_raw$women_involved, preds_m > 0.225)

#accuracy = 0.574187 
#TPR (Recall) = 0.5188
#FPR = 0.4084


#accuracy
(18801+53528 )/(18801+53528+13480+48999)
#0.5365334

#TRP -> Sensitivity & Recall all the came
18801/(18801+13480)    #predicted true / (all actually true)
#0.5824169
#False Positive Rate => positive & False / Positive
48999/(48999+53528) #predicted true / (actually false)
#0.4779131
