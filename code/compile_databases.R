# Imports ----
library(dplyr)
library(plyr) # for rbind.fill()
library(haven) # for read_sav()
source("code/compiled_data_json.R")

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
foodbrain_data <- foodbrain_data[, grepl("id|v1_date|v6_date|sex|age_yr|ethnicity|race|income|^dxa_", names(foodbrain_data))] 
foodbrain_data <- foodbrain_data[, -grep("^v7", names(foodbrain_data))] 

# add id_data$CEBL_ID to foodbrain_data, matching foodbrain_data$id on id_data$r01_food_brain
foodbrain_data <- left_join(foodbrain_data, id_data[,c("r01_food_brain", "CEBL_ID")], by=c('id'='r01_food_brain'))

# convert dexa columns to numeric 
foodbrain_data[grep("dxa", names(foodbrain_data))] <- lapply(foodbrain_data[grep("dxa", names(foodbrain_data))], as.numeric)

# replace un-ordered factor values with labels and convert to characters
foodbrain_data$race <- as.character(sjlabelled::as_label(foodbrain_data$race))
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


# REACH ----

# load data
reach_demo <- read.delim("data/databases/reach/demographics.tsv", na.strings = "n/a") # contains demo and bmi data
reach_dexa <- read.delim("data/databases/reach/dexa.tsv", na.strings = "n/a") # contains dexa data
reach_participants <- read.delim("data/databases/reach/participants.tsv", na.strings = "n/a") # contains MRI date (child_protocol_2_date) 

# merge reach baseline data (ses-1) and v2 date
reach_data <- merge(reach_demo[reach_demo$session_id == "ses-1", ], reach_dexa[reach_dexa$session_id == "ses-1", ], by = c("participant_id", "session_id"), all = TRUE)
reach_data <- merge(reach_data, reach_participants[,c("participant_id", "child_protocol_2_date")], by = c("participant_id"), all = TRUE)

# remove columns
reach_data <-
  reach_data[, !names(reach_data) %in% c(
    "session_id",
    "date_session_start",
    "child_bmi_criteria",
    "visit_protocol",
    "risk_status_maternal", "maternal_anthro_method", "maternal_bmi",
    "dxa_dob", "dxa_sex", "dxa_ethnicity", "dxa_height", "dxa_weight" ,"dxa_age"
  )]

# reformat study ID to be "reach-{ID}" 
reach_data$participant_id <- gsub("sub", "reach", reach_data$participant_id)

# add CEBL ID from master-id_database.csv
reach_data <- left_join(reach_data, id_data[,c("REACH", "CEBL_ID")], by=c('participant_id'='REACH'))

# rename columns
names(reach_data)[names(reach_data) == "participant_id"] <- "study_id"
names(reach_data)[names(reach_data) == "demo_income"] <- "income"
names(reach_data)[names(reach_data) == "child_protocol_2_date"] <- "mri_date"
names(reach_data)[names(reach_data) == "child_age"] <- "age_yr"
names(reach_data)[names(reach_data) == "dxa_scan_date"] <- "dxa_date"

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

# Export ----

# export csv
write.csv(
  combined_data,
  "data/databases/compiled_data.csv",
  quote = FALSE,
  row.names = FALSE
)

# export json
filename_json <- "data/databases/compiled_data.json"
write(compiled_data_json(), filename_json)
