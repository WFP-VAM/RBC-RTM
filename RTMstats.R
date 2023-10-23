library(dplyr)
library(RODBC)
library(tidyr)
library(survey)
library(readxl)
#library(reshape2)
library(stringr)
#options(survey.lonely.psu="adjust")

input = read_excel("AnalysisInput.xlsx") # follow the structure of the analysis input template which allows to run the analysis for one country at a time for a specific round

###Establish a direct connection with the SQL server
params = c("", "")
connection <- odbcConnect("", uid = params[1], pwd = params[2])

table_name = input$table[1]
SvyID = as.character (input$svyid[1])
SvyID_prv = as.character(input$svyid[1] -1)
PnlID = as.character(input$pnlid[1])
qry1 = paste ("SELECT * from " , table_name , " Where SvyID = " , SvyID)
df <- sqlQuery(connection, qry1)
qry2 = paste ("SELECT * from " , table_name , " Where SvyID = " , SvyID_prv)
df_prv <- sqlQuery(connection, qry2)
qry3 = paste ("SELECT * from Strata Where pnlID = " , PnlID)
strata <- sqlQuery(connection, qry3)

#########################################################################
## create survey Design Object
#########################################################################
strata = strata %>%dplyr::select (STR1_NAME , input$Population[1]) %>% filter(!duplicated(strata$STR1_NAME))
names(strata)[1] = 'ADM1_NAME'
df = strata %>% right_join(df)
df$FCG = as.factor(df$FCG)
df_prv = strata %>% right_join(df_prv)
df_prv$FCG = as.factor(df_prv$FCG)
df_all = rbind(df , df_prv)
df_all$SvyID = as.factor(df_all$SvyID)
df_weighted = svydesign( data = df , ids = ~1 , weights = ~1 , strata =  ~ADM1_NAME , fpc = ~Population6)
df_prv_weighted = svydesign( data = df_prv , ids = ~1 , weights = ~1 , strata =  ~ADM1_NAME , fpc = ~Population6)
df_all_weighted = svydesign( data = df_all , ids = ~1 , weights = ~1 , strata = ~ADM1_NAME, fpc = ~Population6 )
##################################################
##analysis for numeric dependent variables##
##################################################
grp_fun <- function( var1 , var2 , design , fun){ svyby(formula = as.formula( paste0( "~" , var2 ) ) , by = as.formula(paste0("~" , var1))   ,design , FUN = fun , na.rm = TRUE ) }
grp_fun_quant <- function(var1 , var2, design, q){ svyby(formula = as.formula( paste0( "~" , var2 ) ), by = as.formula( paste0( "~" , var1 ) ), design, svyquantile, quantiles=q,ci=TRUE,vartype="ci")}
res_df = data.frame()
#calculate mean and statndard error for current and previous rounds
for ( var1 in input$indpvars){
      if (!str_detect(var1, "\\+")){
      v = getElement(df_weighted$variables, var1)
      if(sum(!is.na(v)) == 0) {next}
      print (paste0("indpvar is " , var1))
      print ("------------------")
      res1= svytable(as.formula(paste0("~" , var1)) , df_weighted)%>%as.data.frame()
      depend_vars = unlist (strsplit(input$depvars_num [input$indpvars == var1 ] , ','))
      for (var2 in depend_vars){
            print (paste0("depvars is " , var2))
       res2 = grp_fun(var1 , var2 , df_weighted , svymean)
       res = full_join(res1,res2)
       res$indpvar = names(res)[1]
       res$depvar = names(res) [3]
       names(res)[1] = 'dmgrph'
       names(res)[3] = 'mean'
       res = res[,c(5,6,1,2,3,4)]
       res$sd = sqrt(res$Freq) * res$se

       v1 = getElement(df_prv_weighted$variables, var1)
       if(sum(!is.na(v1)) == 0){res$prvmean = NA ; res$prvse = NA;  res_df = rbind(res_df,res);  next}
       res3 = grp_fun(var1, var2 , df_prv_weighted , svymean)
       res3$indpvar = names(res3)[1]
       res3$depvar = names(res3)[2]
       names(res3)[1] = 'dmgrph'
       names(res3) [2] = 'prvmean'
       names(res3)[3] = 'prvse'
       res3$dmgrph = as.factor(res3$dmgrph)
       res = full_join(res,res3)
       res_df = rbind(res_df,res)

      }
      
      }
      else {
      print (paste0("indpvar is " , var1))
      print ("------------------")      
      res1= svytable(as.formula(paste0("~" , var1)) , df_weighted)%>%as.data.frame()
      depend_vars = unlist (strsplit(input$depvars_num [input$indpvars == var1 ] , ','))
      for (var2 in depend_vars){
            print (paste0("depvars is " , var2))
            res2 = grp_fun(var1 , var2 , df_weighted , svymean)
            res2$dmgrph = rownames(res2)
            res = full_join(res1,res2)
            res = res %>% select (- c(1,2))
            res$indpvar = var1
            res$depvar = names (res)[2]
            names(res)[2] = 'mean'
            res = res[,c(5,6,4,1,2,3)]
            res$sd = sqrt(res$Freq) * res$se
            
            res3 = grp_fun(var1 , var2 , df_prv_weighted , svymean)
            res3$dmgrph = rownames(res3)
            res3 = res3 %>% select (- c(1,2))
            res3$indpvar = var1
            res3$depvar = names(res3)[1]
            names(res3)[1] = 'prvmean'
            names(res3)[2] = 'prvse'
            res = full_join(res,res3)
            res_df = rbind(res_df,res)
            
      }
      }
}
##################################
#Calculate quantiles for current round
#################################
res_df2 = data.frame() 
for (var1 in input$indpvars){
      v = getElement(df_weighted$variables, var1)
      if(sum(!is.na(v)) == 0) {next}
      
      print (var1)
      print ("-----------------------------" )
      depend_vars = unlist (strsplit(input$depvars_num [input$indpvars == var1 ] , ','))
      for (var2 in depend_vars){
            print (var2)
            res1 = svyby(formula = as.formula(paste0("~", var2)) , by = as.formula(paste0("~", var1)) , design = df_weighted ,FUN = svyquantile, quantiles = 0.5 , keep.var=FALSE) #, method="constant")

            names(res1)[2] = 'quantile_value'
            res1$quantile = 'median'
            res2 = svyby(formula = as.formula(paste0("~", var2)) , by = as.formula(paste0("~", var1)) , design = df_weighted ,FUN = svyquantile, quantiles = 0.25 , keep.var=FALSE) #, method="constant")
            
            names(res2)[2] = 'quantile_value'
            res2$quantile = 'q1'
            res3 = svyby(formula = as.formula(paste0("~", var2)) , by = as.formula(paste0("~", var1)) , design = df_weighted ,FUN = svyquantile, quantiles = 0.75 , keep.var=FALSE) #, method="constant")
        
            names(res3)[2] = 'quantile_value'
            res3$quantile = 'q3'
            res = rbind (res1,res2)
            res = rbind(res,res3)
            res$indpvar = var1
            res$depvar = var2
            names(res)[1] = 'dmgrph' 
            res = res[,c(4,5,1,3,2)]
            res_df2 = rbind (res_df2 , res)
      }
}

res_df2 = res_df2 %>% filter (res_df2$quantile == 'median')
res_df2 = res_df2 %>% select (-4)
names(res_df2)[4] = 'median'
res_all = full_join(res_df , res_df2)

#######################################################
#Test the significane of change between two rounds
######################################################
res_df3 = data.frame()

for (var1 in input$indpvars){
      print (paste0("indpvar is " , var1))
      print ("------------------")
      v = as.factor (getElement(df_all_weighted$variables, var1))
      v1 = as.factor (getElement(df_prv_weighted$variables, var1))
      if (sum(!is.na(v1)) == 0) {next}
      v2 = as.factor (getElement(df_weighted$variables, var1))
      if (sum(!is.na(v2)) == 0) {next}
      if (length(levels(v1)) != length(levels(v2))) {next}
      
      depend_vars = unlist (strsplit(input$depvars_num [input$indpvars == var1 ] , ','))

      for (l in levels(v)){
            print (paste0("current level is " , l))
            print ('---------------------------------')
            for (var2 in depend_vars){
                  print (paste0("depvar is " , var2))
                  formula = as.formula(paste0(var2, '~' , 'SvyID'))
                   print (formula)
                   subdesign = subset(df_all_weighted, !is.na(var2) & v ==l)
                   v2 = getElement(subdesign$variables, var2)
                   if(any(is.na(v2))){next}
                   
                  x = svyttest(formula , subdesign ,na.rm = T)
                  pval = x$p.value
                  lower.bound = x$conf.int[1]
                  upper.bound = x$conf.int[2]
                  res= data.frame(indpvar = var1, depvar = var2 , dmgrph = l , pvalue = pval , lower95CI = lower.bound , upper95CI = upper.bound)
                  res_df3 = rbind(res_df3,res)



            }
      }
}
res_all = full_join(res_all, res_df3)
#################################################################################
##analysis for categorical dependent variables##
##################################################
res_df4 = data.frame()
for ( var1 in input$indpvars){
      if (!str_detect(var1, "\\+")){
      v = getElement(df_weighted$variables, var1)
      if(sum(!is.na(v)) == 0) {next}
      print (var1)
      print ("------------------")
      res1= svytable(as.formula(paste0("~" , var1)) , df_weighted)%>%as.data.frame()
      depend_vars = unlist (strsplit(input$depvars_cate [input$indpvars == var1 ] , ','))
      for (var2 in depend_vars){
            print (var2)
            res2 = grp_fun(var1 , var2 , df_weighted , svymean)
            res = full_join(res1,res2)
            res = res[,c(1,2,4 ,6)]
            names(res)[1] = 'dmgrph'
            names(res)[3] = 'mean'
            names(res)[4] = 'se'
            res$depvar = var2
            res$indpvar = var1
            res$sd = sqrt(res$Freq) * res$se
            v1 = getElement(df_prv_weighted$variables, var1)
            if(sum(!is.na(v1)) == 0){res$prvmean = NA ; res$prvse = NA;  res_df4 = rbind(res_df4,res);  next}
            
            res3 = grp_fun(var1, var2 , df_prv_weighted , svymean)
            res3 = res3[,c(1,3,5)]
            names(res3)[1] = 'dmgrph'
            names(res3)[2] = 'prvmean'
            names(res3)[3] = 'prvse'
            res = full_join(res,res3)
            res_df4 = rbind(res_df4,res)
      }
      } else {
            print (paste0("indpvar is " , var1))
            print ("------------------")      
            res1= svytable(as.formula(paste0("~" , var1)) , df_weighted)%>%as.data.frame()
            depend_vars = unlist (strsplit(input$depvars_cate [input$indpvars == var1 ] , ','))
            for (var2 in depend_vars){
                  print (paste0("depvars is " , var2))
                  res2 = grp_fun(var1 , var2 , df_weighted , svymean)
                  res2$dmgrph = rownames(res2)
                  res = full_join(res1,res2)
                  res = res %>% select (- c(1,2,4,6))
                  res$indpvar = var1
                  res$depvar = var2
                  names(res)[2] = 'mean'
                  names(res)[3] = 'se'
                  res = res[,c(5,6,4,1,2,3)]
                  res$sd = sqrt(res$Freq) * res$se
                  
                  res3 = grp_fun(var1 , var2 , df_prv_weighted , svymean)
                  res3$dmgrph = rownames(res3)
                  res3 = res3 %>% select (- c(1,2,3,5))
                  res3$indpvar = var1
                  res3$depvar = var2
                  names(res3)[1] = 'prvmean'
                  names(res3)[2] = 'prvse'
                  res = full_join(res,res3)

                  res_df4 = rbind(res_df4,res)
                  
      
}

}
}

res_df4 = res_df4 [,c(6,5,1,2,3,4,7,8,9)]
###########################################################################
#Test of Significance 
###################################

res_df5 = data.frame()

for (var1 in input$indpvars){
      print ('--------------------------')
      print (var1)
      v = as.factor (getElement(df_all_weighted$variables, var1))
      if (sum(!is.na(v)) == 0) {next}
      v1 = as.factor (getElement(df_prv_weighted$variables, var1))
      if (sum(!is.na(v1)) == 0) {next}
      v2 = as.factor (getElement(df_weighted$variables, var1))
      if (sum(!is.na(v2)) == 0) {next}
      if (length(levels(v1)) != length(levels(v2))) {next}

      
      depend_vars = unlist (strsplit(input$depvars_cate [input$indpvars == var1 ] , ','))
      
      for (l in levels(v)){
            print (l)
            print ('---------------------------------')
            for (var2 in depend_vars){
                  print (var2)

                  formula = as.formula(paste0(var2, '~' , 'SvyID'))
                  print (formula)
                  subdesign = subset(df_all_weighted, !is.na(var2) & v ==l)
                  
                  adjustVar2 = gsub("\\>.*","",var2)
                  adjustVar2 = str_trim( adjustVar2, "left") 
                  print (adjustVar2)
                  v2 = getElement(subdesign$variables, adjustVar2)
                  print (length(v2))
                  if(any(is.na(v2))){next}
                  
                  x = svyttest(formula , subdesign ,na.rm = T)
                  pval = x$p.value
                  lower.bound = x$conf.int[1]
                  upper.bound = x$conf.int[2]
                  res= data.frame(indpvar = var1, depvar = var2 , dmgrph = l , pvalue = pval , lower95CI = lower.bound , upper95CI = upper.bound)
                  res_df5 = rbind(res_df5,res)
                  
                  
                  
            }
      }
}
res_df5 = full_join(res_df4, res_df5)
res_all = full_join(res_all, res_df5)
res_all$SvyID = SvyID
res_all$PnlID = PnlID
res_all$ADM0_NAME = df$ADM0_NAME[1]
res_all$SvyDate = df$SvyDate[1]
res_all <- res_all[, c("SvyID", "PnlID", "SvyDate" , "ADM0_NAME" , "indpvar" , "depvar" , "dmgrph" , "Freq" , "mean" , "prvmean" , "se" , "prvse" , "sd" , "median" , "pvalue" , "lower95CI" , "upper95CI")]
res_all$Freq = round(res_all$Freq)
write.csv(res_all , 'Syria_RTM_analysis.csv')


#upload the results in sql database (Master_RTMStats table)
del_query <- sprintf(paste ("DELETE from mvamStats Where SvyID = " , SvyID))
sqlQuery(connection, del_query)
sqlSave(channel =  connection , dat= res_all , tablename = 'Master_RTMStats' , append = T, rownames =  F )

