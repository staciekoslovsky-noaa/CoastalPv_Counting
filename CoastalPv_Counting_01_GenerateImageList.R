# Coastal Pv Surveys: Generate image list for counting
# S. Koslovsky

# Set variables --------------------------------------------------
photog_date_id <- 'CLC_20230802'
counter <- 'Your Name'

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

# Run code -------------------------------------------------------
year <- substr(photog_date_id, 5, 8)
date <- paste(substr(photog_date_id, 5, 8), substr(photog_date_id, 9, 10), substr(photog_date_id, 11, 12), sep = '-')
photographer <- substr(photog_date_id, 1, 3)

# Connect to DB
con <- RPostgreSQL::dbConnect(PostgreSQL(), 
                              dbname = Sys.getenv("pep_db"), 
                              host = Sys.getenv("pep_ip"), 
                              # User credentials -- use this one!
                              user = Sys.getenv("pep_user"),
                              password = Sys.getenv("user_pw"))
                              # Admin credentials -- SMK only
                              # user = Sys.getenv("pep_admin"),
                              # password = Sys.getenv("admin_pw"))
to_be_counted <- RPostgreSQL::dbGetQuery(con, paste0("SELECT source_file FROM surv_pv_cst.tbl_image_exif WHERE photog_date_id = \'", photog_date_id, "\' AND use_for_count_lku = \'Y\' ORDER BY source_file"))

# Insert records into tbl_image_count
images <- basename(to_be_counted$source_file)
for (i in 1:length(images)) {
  RPostgreSQL::dbSendQuery(con, paste0("INSERT INTO surv_pv_cst.tbl_image_count (image_name, count_type_lku, count_by, count_compromised, representative) SELECT \'", images[i], "\', \'P\', \'", counter, "\', \'False\', \'False\' WHERE NOT EXISTS (SELECT image_name FROM surv_pv_cst.tbl_image_count WHERE image_name = \'", images[i], "\')"))
}

# Create folders, as needed
counted_folder <- '\\\\akc0ss-n086\\NMML_Polar_Imagery\\Surveys_HS\\Coastal\\Counted\\'

if (file.exists(paste0(counted_folder, year))) {
  if (file.exists(paste0(counted_folder, year, '\\', date))) {
    if (file.exists(paste0(counted_folder, year, '\\', date, '\\', photographer))) {
      print("Folder already exists")
      setwd(file.path(paste0(counted_folder, year, '\\', date, '\\', photographer)))
    } else {
      dir.create(file.path(paste0(counted_folder, year, '\\', date, '\\', photographer)))
      setwd(file.path(paste0(counted_folder, year, '\\', date, '\\', photographer)))
    } 
  } else {
    dir.create(file.path(paste0(counted_folder, year, '\\', date)))
    dir.create(file.path(paste0(counted_folder, year, '\\', date, '\\', photographer)))
    setwd(file.path(paste0(counted_folder, year, '\\', date, '\\', photographer)))
  }
} else {
  dir.create(file.path(paste0(counted_folder, year)))
  dir.create(file.path(paste0(counted_folder, year, '\\', date)))
  dir.create(file.path(paste0(counted_folder, year, '\\', date, '\\', photographer)))
  setwd(file.path(paste0(counted_folder, year, '\\', date, '\\', photographer)))
}

# Export image list to newly created folder
write.table(to_be_counted, paste0("coastalPv_", photog_date_id, "_rgb_images.txt"), row.names = FALSE, col.names = FALSE, quote = FALSE)
