# Imports ----
library(dplyr)
library(plyr) # for rbind.fill()
library(haven) # for read_sav()
source("code/compiled_data_json.R")


# MRI file names ----
mri_files <- read.csv("data/databases/mri_filenames.csv", header = FALSE)
mri_subs <- gsub("\\_.*", "", mri_files$V1)

# ID data ----

# load data
id_data <- read.csv("data/databases/id-data.csv", na.strings = "")

# remove rows where r01_food_brain and REACH columns are NA
id_data <- id_data[!(is.na(id_data$REACH) & is.na(id_data$r01_food_brain))  ,]

# format IDs to match mri data
id_data$r01_food_brain <- gsub('R01_', 'foodbrain-', id_data$r01_food_brain)
id_data$REACH <- gsub('REACH_', 'reach-', id_data$REACH)


# Food and Brain ----

# load data
foodbrain_anthro <- read_sav("data/databases/foodbrain/anthro_data.sav") # contains demo, dexa, and bmi data
foodbrain_dates <- read_sav("data/databases/foodbrain/visit_notes.sav") # contains visit dates

# merge anthro and dates
foodbrain_data <- merge(foodbrain_anthro, foodbrain_dates[, c("id", "v6_date")], by = "id", all = TRUE)

# reformat study ID to be "reach-{ID}" 
foodbrain_data$id <- sprintf("foodbrain-%03d", foodbrain_data$id)

# select columns for sharing (add maternal ed?)
foodbrain_data <- foodbrain_data[, grepl("id|v1_date|v6_date|sex|age_yr|ethnicity|race|income|^bmi$|bmi_z|bmi_percentile|^dxa_", names(foodbrain_data))] 
foodbrain_data <- foodbrain_data[, -grep("^v7", names(foodbrain_data))] 

# add id_data$CEBL_ID to foodbrain_data, matching foodbrain_data$id on id_data$r01_food_brain
foodbrain_data <- left_join(foodbrain_data, id_data[,c("r01_food_brain", "CEBL_ID")], by=c('id'='r01_food_brain'))

# convert dexa columns to numeric 
foodbrain_data[grep("dxa", names(foodbrain_data))] <- lapply(foodbrain_data[grep("dxa", names(foodbrain_data))], as.numeric)

# replace un-ordered factor values with labels and convert to characters
foodbrain_data$race <- as.character(sjlabelled::as_label(foodbrain_data$race))
foodbrain_data$sex <- as.character(sjlabelled::as_label(foodbrain_data$sex))
foodbrain_data$ethnicity <- as.character(sjlabelled::as_label(foodbrain_data$ethnicity))

# replace "White/Caucasian" with "White" to match reach 
foodbrain_data$race <- ifelse(foodbrain_data$race == "White/Caucasian", "White", foodbrain_data$race)

# rename columns
names(foodbrain_data)[names(foodbrain_data) == "v1_date"] <- "dxa_date"
names(foodbrain_data)[names(foodbrain_data) == "id"] <- "study_id"
names(foodbrain_data)[names(foodbrain_data) == "v6_date"] <- "mri_date"
names(foodbrain_data)[names(foodbrain_data) == "dxa_bodyfat_ptile"] <- "dxa_total_body_perc_fat_ptile" # use variable name from reach
names(foodbrain_data)[names(foodbrain_data) == "dxa_fatmass_trunk_legs_ratio"] <- "dxa_fatmass_trunk_limb_ratio" # use variable name from reach
names(foodbrain_data)[names(foodbrain_data) == "dxa_fatmass_trunk_legs_ratio_ptile"] <- "dxa_fatmass_trunk_limb_ratio_ptile" # use variable name from reach


# Load REACH ----

# # get most up to date reach phenotype databases
# 
# reach_phe_prefixes <- c("anthropometrics", "demographics", "dexa", "mri_visit", "dataset_description")
# reach_phe_dir = "/Users/baf44/Library/CloudStorage/OneDrive-ThePennsylvaniaStateUniversity/b-childfoodlab_Shared/Active_Studies/MarketingResilienceRO1_8242020/ParticipantData/bids/phenotype"
# 
# # Loop through each prefix and copy the matching files
# for (db_prefix in reach_phe_prefixes) {
#   
#   # list files in reach_phe_dir that start with the current prefix
#   files_to_copy <- list.files(reach_phe_dir, pattern = paste0("^", db_prefix), full.names = TRUE)
#   
#   # copy files
#   file.copy(files_to_copy, "data/databases/reach")
# }

# load data
reach_demo <- read.delim("data/databases/reach/demographics.tsv", na.strings = "n/a") # contains demo and bmi data
reach_dexa <- read.delim("data/databases/reach/dexa.tsv", na.strings = "n/a") # contains dexa data
reach_mri <- read.delim("data/databases/reach/mri_visit.tsv", na.strings = "n/a") # contains mri date


# merge reach baseline data (ses-1) and v2 date
reach_data <- merge(reach_demo[reach_demo$session_id == "ses-1", ], reach_dexa[reach_dexa$session_id == "ses-1", ], by = c("participant_id", "session_id"), all = TRUE)
reach_data <- merge(reach_data, reach_mri[,c("participant_id", "v2_date")], by = c("participant_id"), all = TRUE)

# remove columns
reach_data <-
  reach_data[, !names(reach_data) %in% c(
    "session_id",
    "date_session_start",
    "child_bmi_criteria",
    "visit_protocol",
    "risk_status_maternal", "maternal_anthro_method", "maternal_bmi", "demo_education_mom",
    "dxa_dob", "dxa_sex", "dxa_ethnicity", "dxa_height", "dxa_weight" ,"dxa_age"
  )]

# reformat study ID to be "reach-{ID}" 
reach_data$participant_id <- gsub("sub", "reach", reach_data$participant_id)

# add CEBL ID from master-id_database.csv
reach_data <- left_join(reach_data, id_data[,c("REACH", "CEBL_ID")], by=c('participant_id'='REACH'))

# rename columns
names(reach_data)[names(reach_data) == "participant_id"] <- "study_id"
names(reach_data)[names(reach_data) == "demo_income"] <- "income"
names(reach_data)[names(reach_data) == "v2_date"] <- "mri_date"
names(reach_data)[names(reach_data) == "child_age"] <- "age_yr"
names(reach_data)[names(reach_data) == "dxa_scan_date"] <- "dxa_date"
names(reach_data)[names(reach_data) == "child_bmi"] <- "bmi"
names(reach_data)[names(reach_data) == "child_bmi_p"] <- "bmi_percentile"
names(reach_data)[names(reach_data) == "child_bmi_z"] <- "bmi_z"

# replace factor values with labels that match food and brain 
reach_data <- reach_data %>%
  mutate(ethnicity = recode(ethnicity, `0` = "NOT Hispanic or Latino", `1` = "Hispanic or Latino"),
         sex = recode(sex, "male" = "Male", "female" = "Female"),
         race = recode(race, `0` = "American Indian/Alaskan Native", `1` = "Asian", `2` = "Black or African American", `3` = "White", `4` = "Hawaiian/Pacific Islander", `5` = "Other")
         )


# Merge ----
combined_data <- rbind.fill(reach_data, foodbrain_data) # should be able to use rbind when all columns match

# reorder cols
combined_data <-
  combined_data %>%
  dplyr::relocate("CEBL_ID") %>% #move CEBL_ID to first col
  dplyr::relocate("study_id", .after = 1) %>%
  dplyr::relocate("dxa_date", .after = 2) %>%
  dplyr::relocate("mri_date", .after = 3)

# only retain IDs that have MRI data
combined_data <- combined_data[combined_data$study_id %in% mri_subs, ]

# remove dxa_total_body_perc_fat and dxa_total_body_perc_fat_ptile columns -- these are equivalent to dxa_total_perc_fat and dxa_total_perc_fat_ptile
combined_data <- combined_data[, !names(combined_data) %in% c("dxa_total_body_perc_fat","dxa_total_body_perc_fat_ptile")]

# Export ----

# export csv
write.csv(
  combined_data,
  paste0("data/databases/compiled_data_",Sys.Date(),".csv"),
  quote = FALSE,
  row.names = FALSE
)

# export json
filename_json <- "data/databases/compiled_data.json"
write(compiled_data_json(), filename_json)
