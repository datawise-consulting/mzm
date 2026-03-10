### setup
packages <- c(
  "tidyverse",
  "dplyr",
  "sf",
  "svDialogs",
  "googlesheets4",
  "googledrive",
  "stringr",
  "magrittr",
  "readxl",
  "rlist"
)
# new_packages <- packages[!(packages %in% installed.packages()[, "Package"])] # not working for some reason
# if (length(new_packages)) {
#   install.packages(new_packages)
# }
lapply(packages, library, character.only = TRUE)

proj_root <- file.path(
  "C:",
  "Users",
  Sys.getenv("USERNAME"),
  "DataWise Consulting, LLC/DataWise SharePoint - Documents/Projects/2243 MAP Zoning Atlas"
)
setwd(proj_root)

