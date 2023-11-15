# Import coastal harbor seal annotations to DB
# S. Koslovsky

# Set variables --------------------------------------------------
photog_date_id <- 'CLC_20230802'
file_name <- 'coastalPv_CLC_20230802_rgb_annotations.csv'

# Create functions -----------------------------------------------
# Function to install packages needed
install_pkg <- function(x)
{
  if (!require(x,character.only = TRUE))
  {
    install.packages(x,dep=TRUE)
    if(!require(x,character.only = TRUE)) stop("Package not found")
  }
}

# Install libraries ----------------------------------------------
install_pkg("RPostgreSQL")
install_pkg("tidyverse")

# Process data ---------------------------------------------------

# Set up working environment
"%notin%" <- Negate("%in%")

counted_folder <- '\\\\akc0ss-n086\\NMML_Polar_Imagery\\Surveys_HS\\Coastal\\Counted\\'
year <- substr(photog_date_id, 5, 8)
date <- paste(substr(photog_date_id, 5, 8), substr(photog_date_id, 9, 10), substr(photog_date_id, 11, 12), sep = '-')
photographer <- substr(photog_date_id, 1, 3)

wd <- paste0(counted_folder, year, '\\', date, '\\', photographer)
setwd(wd)

con <- RPostgreSQL::dbConnect(PostgreSQL(), 
                              dbname = Sys.getenv("pep_db"), 
                              host = Sys.getenv("pep_ip"), 
                              # User credentials -- use this one!
                              user = Sys.getenv("pep_user"),
                              password = Sys.getenv("user_pw"))
                              # Admin credentials -- SMK only
                              # user = Sys.getenv("pep_admin"),
                              # password = Sys.getenv("admin_pw"))

# Delete data from tables, if previously imported
RPostgreSQL::dbSendQuery(con, paste0("DELETE FROM surv_pv_cst.tbl_detections_manualreview_rgb WHERE photog_date_id = \'", photog_date_id, "\'"))

# Import data and process
manual_id <- RPostgreSQL::dbGetQuery(con, "SELECT max(id) FROM surv_pv_cst.tbl_detections_manualreview_rgb") 
manual_id$max <- ifelse(is.na(manual_id$max), 0, manual_id$max)
    
manual <- read.csv(file_name, skip = 2, header = FALSE, stringsAsFactors = FALSE, 
                      col.names = c("detection", "image_name", "frame_number", "bound_left", "bound_top", "bound_right", "bound_bottom", "score", "length", "detection_type", "type_score"))
    
if (nrow(manual) > 0) {
  manual <- manual %>%
    mutate(image_name = basename(sapply(strsplit(image_name, split= "\\/"), function(x) x[length(x)]))) %>%
    mutate(id = 1:n()) %>% # + manual_id$max) %>%
    mutate(detection_file = file_name) %>%
    mutate(photog_date_id = photog_date_id) %>%
    mutate(detection_id = paste(photog_date_id, detection, sep = "_")) %>%
    select("id", "detection", "image_name", "frame_number", "bound_left", "bound_top", "bound_right", "bound_bottom", "score", "length", "detection_type", "type_score", 
           "photog_date_id", "detection_id", "detection_file")

  # Import data to DB
  RPostgreSQL::dbWriteTable(con, c("surv_pv_cst", "tbl_detections_manualreview_rgb"), manual, append = TRUE, row.names = FALSE)
}

# Disconnect from DB
RPostgreSQL::dbDisconnect(con)
rm(con)
