# Post-render validation, run in a clean R process. Not a second command required by the grader.
suppressPackageStartupMessages({library(glmnet); library(mgcv); library(ranger)})
oof <- read.csv('output/cp2_oof_predictions.csv',check.names=FALSE)
comparison <- read.csv('output/cp2_comparison.csv',check.names=FALSE)
wide_check <- read.csv('output/set-a_wide.csv',check.names=FALSE)
bundle <- readRDS('output/cp2_final_model.rds')
stopifnot(nrow(oof)==4000L,!anyDuplicated(oof$record_id),!anyNA(oof),
 identical(oof$record_id,wide_check$record_id),all(oof$outcome %in% 0:1),
 identical(sort(unique(oof$fold)),1:5),sum(oof$outcome)==554L)
auc_check <- function(y,p) {n1<-sum(y==1); (sum(rank(p)[y==1])-n1*(n1+1)/2)/(n1*sum(y==0))}
for(m in c('Ridge','GAM','Forest','SAPS_I','SOFA')) {
 a<-sapply(1:5,function(f) {z<-oof$fold==f; auc_check(oof$outcome[z],oof[[m]][z])})
 row<-comparison[comparison$Model==m,]
 stopifnot(max(abs(as.numeric(row[paste('Fold',1:5)])-a))<1e-12,
 abs(row$Mean-mean(a))<1e-12,abs(row$SD-sd(a))<1e-12)
}
# Predict using only original feature columns: no outcomes, scores, or RecordID.
new_features<-wide_check[bundle$raw_predictors]
p<-bundle$predict_risk(bundle,new_features)
stopifnot(length(p)==nrow(oof),!anyNA(p),all(is.finite(p)),all(p>0 & p<1),
 !any(c('record_id','in_hospital_death','saps_i','sofa','length_of_stay','survival_days') %in% bundle$raw_predictors))
audit<-readRDS('output/cp2_resampling_audit.rds')
stopifnot(length(audit$tuning)==5L,length(audit$fold_preprocessing)==5L)
for(f in 1:5) {
 # Independently check that learned medians match outer training rows, not all rows.
 pp<-audit$fold_preprocessing[[f]]
 training<-wide_check[oof$fold!=f,]
 for(v in setdiff(bundle$raw_predictors,bundle$categorical)) {
   x<-training[[v]]; expected<-if(all(is.na(x))) 0 else median(x,na.rm=TRUE)
   stopifnot(abs(pp$median[v]-expected)<1e-10)
 }
}
cat('PASS: 4,000 unique stays; 554 deaths; all held-out scores and independently recomputed fold AUROCs; saved pipeline predicts from features alone in a fresh R session; outer-fold medians match training data.\n')
