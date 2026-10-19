suppressPackageStartupMessages({library(glmnet); library(ranger); library(mgcv); library(ggplot2)})
SEED <- 7072026L
set.seed(SEED)
auc <- function(y, p) {
 stopifnot(length(y)==length(p), !anyNA(p), all(is.finite(p)), length(unique(y))==2)
 n1 <- sum(y==1); (sum(rank(p)[y==1])-n1*(n1+1)/2)/(n1*sum(y==0))
}
logloss <- function(y,p) {p <- pmin(pmax(p,1e-8),1-1e-8); mean(-y*log(p)-(1-y)*log(1-p))}
folds <- function(y,k,seed) {
 set.seed(seed); z <- integer(length(y)); for (v in 0:1) {ii<-which(y==v); z[ii]<-sample(rep(seq_len(k),length.out=length(ii)))}; z
}
# Definitions are fixed a priori; all fitted statistics come from training rows.
categorical <- c('gender','icu_type')
excluded <- c('record_id','in_hospital_death','saps_i','sofa','length_of_stay','survival_days')
raw_predictors <- setdiff(names(wide),excluded)
stopifnot(!any(excluded %in% raw_predictors))
encode <- function(d) {
 z <- as.data.frame(d[,setdiff(raw_predictors,categorical),drop=FALSE])
 for (v in categorical) {
   lev <- if(v=='gender') 0:1 else 1:4
   # All levels are specified from the data dictionary, including an unknown category.
   for (l in lev) z[[paste0(v,'_',l)]] <- as.numeric(!is.na(d[[v]]) & d[[v]]==l)
   z[[paste0(v,'_unknown')]] <- as.numeric(is.na(d[[v]]))
 }
 as.matrix(z)
}
fit_preprocessor <- function(d) {
 x<-encode(d)
 med<-apply(x,2,function(z) if(all(is.na(z))) 0 else median(z,na.rm=TRUE))
 for(j in seq_len(ncol(x))) x[is.na(x[,j]),j]<-med[j]
 center<-colMeans(x); scale<-apply(x,2,sd); keep<-is.finite(scale)&scale>1e-10
 list(median=med,center=center,scale=scale,keep=keep,raw_predictors=raw_predictors,categorical=categorical)
}
apply_preprocessor <- function(d,pp) {
 x<-encode(d); stopifnot(identical(colnames(x),names(pp$median)))
 for(j in seq_len(ncol(x))) x[is.na(x[,j]),j]<-pp$median[j]
 x<-sweep(sweep(x[,pp$keep,drop=FALSE],2,pp$center[pp$keep]),2,pp$scale[pp$keep],'/')
 stopifnot(!anyNA(x),all(is.finite(x))); x
}
lambdas <- 10^seq(0,-4,length.out=9)
rf_grid <- expand.grid(mtry_fraction=c(.15,.40), min_node_size=c(10L,30L))
rf_fit <- function(x,y,g,seed) ranger(x=as.data.frame(x),y=factor(y,levels=0:1),probability=TRUE,
 num.trees=300,mtry=max(1L,floor(ncol(x)*g$mtry_fraction)),min.node.size=g$min_node_size,
 max.depth=12,num.threads=2,seed=seed)
rf_predict <- function(m,x) predict(m,data=as.data.frame(x),num.threads=2)$predictions[,'1']
tune_models <- function(d,y,seed) {
 f<-folds(y,3,seed); ll_ridge<-matrix(NA_real_,3,length(lambdas)); ll_rf<-matrix(NA_real_,3,nrow(rf_grid))
 for (i in 1:3) {
   tr<-which(f!=i); va<-which(f==i); pp<-fit_preprocessor(d[tr,]); xtr<-apply_preprocessor(d[tr,],pp); xv<-apply_preprocessor(d[va,],pp)
   m<-glmnet(xtr,y[tr],family='binomial',alpha=0,lambda=lambdas,standardize=FALSE)
   pr<-predict(m,xv,s=lambdas,type='response')
   for(j in seq_along(lambdas)) ll_ridge[i,j]<-logloss(y[va],pr[,j])
   for(j in seq_len(nrow(rf_grid))) {m<-rf_fit(xtr,y[tr],rf_grid[j,],seed+100*i+j); ll_rf[i,j]<-logloss(y[va],rf_predict(m,xv))}
 }
 list(lambda=lambdas[which.min(colMeans(ll_ridge))],rf=rf_grid[which.min(colMeans(ll_rf)),],
 ridge_loss=colMeans(ll_ridge),rf_loss=colMeans(ll_rf))
}
smooth_vars <- c('age','GCS_min','BUN_max','Creatinine_last','Lactate_max','HR_max','MAP_min','Temp_last','WBC_max','Platelets_min','RespRate_max','Urine_mean')
gam_linear <- c('Lactate_n','gender_1','gender_unknown','icu_type_2','icu_type_3','icu_type_4','icu_type_unknown')
gam_fit <- function(x,y) {
 sv<-intersect(smooth_vars,colnames(x)); lv<-intersect(gam_linear,colnames(x))
 f<-as.formula(paste('y ~',paste(c(paste0('s(',sv,',k=4,bs="cr")'),lv),collapse='+')))
 dat<-as.data.frame(x); dat$y<-y
 gam(f,data=dat,family=binomial(),method='REML',select=TRUE)
}
y<-wide$in_hospital_death
outer_fold<-folds(y,5,SEED)
oof<-data.frame(record_id=wide$record_id,outcome=y,fold=outer_fold,Ridge=NA_real_,GAM=NA_real_,Forest=NA_real_,SAPS_I=wide$saps_i,SOFA=wide$sofa)
benchmark_missing <- c(SAPS_I=sum(is.na(wide$saps_i)),SOFA=sum(is.na(wide$sofa)))
benchmark_complete <- !is.na(wide$saps_i) & !is.na(wide$sofa)
tuning<-list(); fold_preprocessing<-list()
for (i in 1:5) {
 message('Outer fold ',i,' of 5: inner tuning and held-out predictions')
 tr<-which(outer_fold!=i); va<-which(outer_fold==i)
 for (b in c('SAPS_I','SOFA')) { missing_va<-va[is.na(oof[[b]][va])]; oof[[b]][missing_va]<-median(if(b=='SAPS_I') wide$saps_i[tr] else wide$sofa[tr],na.rm=TRUE) }
 tuning[[i]]<-tune_models(wide[tr,],y[tr],SEED+1000*i)
 pp<-fit_preprocessor(wide[tr,]); fold_preprocessing[[i]]<-pp
 xt<-apply_preprocessor(wide[tr,],pp); xv<-apply_preprocessor(wide[va,],pp)
 mr<-glmnet(xt,y[tr],family='binomial',alpha=0,lambda=lambdas,standardize=FALSE)
 oof$Ridge[va]<-drop(predict(mr,xv,s=tuning[[i]]$lambda,type='response'))
 mg<-gam_fit(xt,y[tr]); oof$GAM[va]<-predict(mg,newdata=as.data.frame(xv),type='response')
 mf<-rf_fit(xt,y[tr],tuning[[i]]$rf,SEED+i); oof$Forest[va]<-rf_predict(mf,xv)
}
models<-c('Ridge','GAM','Forest','SAPS_I','SOFA')
fold_auc<-sapply(models,function(m) sapply(1:5,function(i) auc(y[outer_fold==i],oof[[m]][outer_fold==i])))
comparison<-data.frame(Model=models,t(fold_auc),Mean=colMeans(fold_auc),SD=apply(fold_auc,2,sd),check.names=FALSE)
names(comparison)[2:6]<-paste('Fold',1:5)
complete_case_auc<-sapply(models,function(m) sapply(1:5,function(i) {z<-outer_fold==i & benchmark_complete; auc(y[z],oof[[m]][z])}))
complete_case_comparison<-data.frame(Model=models,N=sum(benchmark_complete),Mean=colMeans(complete_case_auc),SD=apply(complete_case_auc,2,sd))
cv_loss<-sapply(oof[c('Ridge','GAM','Forest')],function(p) logloss(y,p))
# Predeclared selection rule: highest mean outer-fold AUROC; prefer Ridge within 0.01.
best<-names(which.max(colMeans(fold_auc)[1:3]))
final_name<-if(max(colMeans(fold_auc)[1:3])-mean(fold_auc[,'Ridge'])<=.01) 'Ridge' else best
message('Refitting all three models on set-a for reporting; selected model: ',final_name)
final_tuning<-tune_models(wide,y,SEED+9999)
full_pp<-fit_preprocessor(wide); full_x<-apply_preprocessor(wide,full_pp)
full_ridge<-glmnet(full_x,y,family='binomial',alpha=0,lambda=lambdas,standardize=FALSE)
full_gam<-gam_fit(full_x,y)
full_forest<-rf_fit(full_x,y,final_tuning$rf,SEED+10000)
final_model<-switch(final_name,Ridge=full_ridge,GAM=full_gam,Forest=full_forest)
# Functions and preprocessing are bundled to avoid recomputing fitted statistics in CP3.
final_bundle <- list(model_name=final_name,model=final_model,preprocessing=full_pp,lambda=final_tuning$lambda,
 raw_predictors=raw_predictors,categorical=categorical,encode=encode,apply_preprocessor=apply_preprocessor,
 predict_risk=function(bundle,new_wide) {
   raw_predictors<-bundle$raw_predictors; categorical<-bundle$categorical
   environment(bundle$encode)<-environment(); encode<-bundle$encode
   environment(bundle$apply_preprocessor)<-environment()
   x<-bundle$apply_preprocessor(new_wide,bundle$preprocessing)
   switch(bundle$model_name,Ridge=drop(predict(bundle$model,x,s=bundle$lambda,type='response')),
     GAM=predict(bundle$model,newdata=as.data.frame(x),type='response'),
     Forest=predict(bundle$model,data=as.data.frame(x))$predictions[,'1'])
 },seed=SEED,session=sessionInfo())
saveRDS(final_bundle,'output/cp2_final_model.rds')
write.csv(oof,'output/cp2_oof_predictions.csv',row.names=FALSE)
write.csv(comparison,'output/cp2_comparison.csv',row.names=FALSE)
write.csv(data.frame(record_id=wide$record_id,fold=outer_fold),'output/cp2_folds.csv',row.names=FALSE)
saveRDS(list(tuning=tuning,final_tuning=final_tuning,fold_preprocessing=fold_preprocessing), 'output/cp2_resampling_audit.rds')
# Validate bundled prediction function and fold coverage.
# Serialized reload is checked separately by scripts/verify_outputs.R.
bundle<-final_bundle; restored<-bundle$predict_risk(bundle,wide)
expected<-switch(final_name,Ridge=drop(predict(full_ridge,full_x,s=final_tuning$lambda,type='response')),
 GAM=predict(full_gam,newdata=as.data.frame(full_x),type='response'),Forest=rf_predict(full_forest,full_x))
stopifnot(isTRUE(all.equal(unname(restored),unname(expected),tolerance=1e-12)),nrow(oof)==4000L,
 !anyDuplicated(oof$record_id),!anyNA(oof),all(restored>0 & restored<1))
coef_table<-data.frame(Predictor=rownames(coef(full_ridge,s=final_tuning$lambda)),Coefficient=as.numeric(coef(full_ridge,s=final_tuning$lambda)))
coef_table<-coef_table[coef_table$Predictor!='(Intercept)',]; coef_table<-coef_table[order(abs(coef_table$Coefficient),decreasing=TRUE),]
write.csv(coef_table,'output/cp2_ridge_coefficients.csv',row.names=FALSE)
roc_data<-do.call(rbind,lapply(models,function(m) {
 z<-data.frame(p=oof[[m]],y=y); z<-aggregate(y~p,z,function(v)c(n=length(v),d=sum(v))); z<-z[order(z$p,decreasing=TRUE),]
 data.frame(Model=m,FPR=c(0,cumsum(z$y[,'n']-z$y[,'d'])/sum(y==0)),TPR=c(0,cumsum(z$y[,'d'])/sum(y==1)))
}))
roc_plot<-ggplot(roc_data,aes(FPR,TPR,color=Model))+geom_path(linewidth=.8)+geom_abline(slope=1,intercept=0,linetype=2,color='grey60')+
 coord_equal()+labs(x='False positive rate',y='True positive rate',title='Out-of-fold ROC curves: the same 4,000 stays')+theme_minimal(base_size=12)
coef_plot<-ggplot(head(coef_table,25),aes(reorder(Predictor,Coefficient),Coefficient))+geom_col(fill='#256584')+coord_flip()+
 labs(x=NULL,y='Log-odds coefficient per training-set standard deviation',title='Largest 25 ridge coefficients; full table saved as CSV')+theme_minimal(base_size=11)
# Complete coefficient plot, including every retained encoded predictor.
coef_all_plot<-ggplot(coef_table,aes(reorder(Predictor,Coefficient),Coefficient))+geom_segment(aes(xend=Predictor,yend=0),color='#256584')+geom_point(size=.8)+coord_flip()+
 labs(x=NULL,y='Log-odds coefficient per standard deviation',title='All ridge coefficients on a common scale')+theme_minimal(base_size=8)+theme(axis.text.y=element_text(size=5))
ggsave('output/cp2_all_coefficients.png',coef_all_plot,width=11,height=32,limitsize=FALSE,dpi=130)
partial_data<-do.call(rbind,lapply(c('GCS_min','Lactate_max','MAP_min'),function(v) {
 original<-wide[[v]]; grid<-seq(quantile(original,.025,na.rm=TRUE),quantile(original,.975,na.rm=TRUE),length.out=100)
 nd<-as.data.frame(full_x[rep(1,100),,drop=FALSE]); for(j in names(nd)) nd[[j]]<-0
 nd[[v]]<-(grid-full_pp$center[v])/full_pp$scale[v]
 pr<-predict(full_gam,newdata=nd,type='terms',se.fit=TRUE); j<-paste0('s(',v,')')
 data.frame(Predictor=v,Value=grid,Effect=pr$fit[,j],Lower=pr$fit[,j]-1.96*pr$se.fit[,j],Upper=pr$fit[,j]+1.96*pr$se.fit[,j])
}))
partial_plot<-ggplot(partial_data,aes(Value,Effect))+geom_ribbon(aes(ymin=Lower,ymax=Upper),fill='#86b6c9',alpha=.4)+geom_line(color='#164b67',linewidth=.8)+
 facet_wrap(~Predictor,scales='free_x')+labs(x='Observed units (central 95% of nonmissing values)',y='Centered smooth contribution to log odds',title='GAM partial effects with approximate 95% confidence bands')+theme_minimal(base_size=11)
ggsave('output/cp2_roc.png',roc_plot,width=7,height=5,dpi=140)
ggsave('output/cp2_partial_effects.png',partial_plot,width=10,height=4,dpi=140)
write.csv(partial_data,'output/cp2_partial_effects.csv',row.names=FALSE)
write.csv(data.frame(Variable=rownames(summary(full_gam)$s.table),summary(full_gam)$s.table,check.names=FALSE),'output/cp2_gam_smooths.csv',row.names=FALSE)
