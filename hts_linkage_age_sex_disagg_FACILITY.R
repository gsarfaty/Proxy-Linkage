#load packages
library(dplyr)
library(tidyr)


#import data
linkage_data <- ICPI_FactView_Site_IM_Zambia_20170922_v2_1


# change all header names to lower case to make it easier to use
names(linkage_data) <- tolower(names(linkage_data))


#filter and subset for key variables and disaggs
linkage_data2 <-linkage_data %>%
  filter(indicator %in% c("HTS_TST_POS", "HTS_TST_NEG", "TX_NEW"),
           standardizeddisaggregate %in% c("Modality/AgeAboveTen/Sex/Result", "Modality/AgeLessThanTen/Result","AgeLessThanTen","AgeAboveTen/Sex")) %>%
  select(facilityuid,facility,indicator,standardizeddisaggregate,age,sex,resultstatus,fy2017q1,fy2017q2,fy2017q3) %>% 
  group_by(facilityuid,facility,indicator,age,sex,resultstatus,add=TRUE) %>% 
  summarize_at(vars(starts_with("fy2017q")),funs(sum(.,na.rm=TRUE))) %>% 
  ungroup() %>% 
  unite(indicator_unite_,indicator,resultstatus, sep="_") %>% 
  gather(qtr, indicator_unite, starts_with("fy2")) %>% 
  spread(indicator_unite_,indicator_unite) 

#rename columns 
names(linkage_data2)[6] <- "HTS_TST_NEG"
names(linkage_data2)[7] <- "HTS_TST_POS"
names(linkage_data2)[8] <- "TX_NEW"

#create HTS_TST as sum of post and neg disaggs
linkage_data2$HTS_TST <-rowSums(linkage_data2[,6:7], na.rm=TRUE)

#reorder
linkage_data2<-linkage_data2[c(1,2,3,4,5,9,6,7,8)]

#get total numerator for our variables of interest
totalN <- ICPI_FactView_Site_IM_Zambia_20170922_v2_1
names(totalN) <-tolower(names(totalN))

totalN <- totalN %>% 
  filter(indicator %in% c("HTS_TST", "HTS_TST_POS", "HTS_TST_NEG", "TX_NEW") & standardizeddisaggregate=="Total Numerator") %>% 
  select(facilityuid,facility,indicator,standardizeddisaggregate,fy2017q1,fy2017q2,fy2017q3) %>% 
  group_by(facilityuid,facility,indicator,standardizeddisaggregate,add=TRUE) %>% 
  summarize_at(vars(starts_with("fy2017q")),funs(sum(.,na.rm=TRUE))) %>% 
  ungroup() %>% 
  gather(qtr, value, starts_with("fy2")) %>% 
  spread(indicator,value) %>% 
  select(-c(standardizeddisaggregate))

totalN$age <-"Total Numerator"
totalN$sex <-"Total Numerator"

totalN<-totalN[c(1,2,8,9,3,4,5,6,7)]


#combine disagg df with total numerator
Linkage_Final <-rbind(linkage_data2,totalN)

#calculate proxy linkage
Linkage_Final$Linkage <- round((Linkage_Final$TX_NEW/Linkage_Final$HTS_TST_POS)*100,1)

#remove extra dfs
rm(ICPI_FactView_Site_IM_Zambia_20170922_v2_1,linkage_data,linkage_data2,totalN)

#export
write.table(Linkage_Final, file="proxylinkage_Facility_agesex_20170922.txt",  sep="\t")





  
  
