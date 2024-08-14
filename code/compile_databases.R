# Imports ----
library(dplyr)

# ID data ----

# load data
id_data <- read.csv("data/databases/id-data.csv", na.strings = "")

# remove rows where r01_food_brain and REACH columns are NA
id_data <- id_data[!(is.na(id_data$REACH) & is.na(id_data$r01_food_brain))  ,]

# format IDs to match mri data
id_data$r01_food_brain <- gsub('R01_', 'foodbrain-', id_data$r01_food_brain)
id_data$REACH <- gsub('REACH_', 'reach-', id_data$REACH)

# Food and Brain ----

# load anthro data
foodbrain_data <- read_sav("data/databases/foodbrain/anthro_data.sav")

# load data that has date of MRI visit
## figure out which database this is

# reformat study ID to be "reach-{ID}" 
foodbrain_data$id <- sprintf("foodbrain-%03d", foodbrain_data$id)

# select columns for sharing (add maternal ed?)
foodbrain_data <- foodbrain_data[, grepl("id|v1_date|sex|age_yr|ethnicity|race|income|^dxa_", names(foodbrain_data))] 
foodbrain_data <- foodbrain_data[, -grep("^v7", names(foodbrain_data))] 

# add study column 
foodbrain_data$study <- "foodbrain"

# add id_data$CEBL_ID to foodbrain_data, matching foodbrain_data$id on id_data$r01_food_brain
foodbrain_data <- left_join(foodbrain_data, id_data[,c("r01_food_brain", "CEBL_ID")], by=c('id'='r01_food_brain'))

# convert dexa columns to numeric 
foodbrain_data[grep("dxa", names(foodbrain_data))] <- lapply(foodbrain_data[grep("dxa", names(foodbrain_data))], as.numeric)


# rename columns
names(foodbrain_data)[names(foodbrain_data) == "v1_date"] <- "dexa_date"
names(foodbrain_data)[names(foodbrain_data) == "id"] <- "study_id"

## replace vX_date with MRI date

# REACH ----

# load data

# reformat study column 

# add CEBL ID from master-id_database.csv

# reformat study ID to be "reach-{ID}" 


# Merge ----

# row bind -- all columns should match