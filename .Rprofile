source("renv/activate.R")

proj2243_root <- file.path(
  "C:",
  "Users",
  Sys.getenv("USERNAME"),
  "DataWise Consulting, LLC",
  "DataWise Sharepoint - Documents",
  "Projects",
  "2243 MAP Zoning Atlas"
)

# need to test if this id is stable across others' devices. 
# if not, may need to access using API, which will likely be slower.
gdrive_root <- file.path(
  "H:/.shortcut-targets-by-id/1hw_gGJyOaJMLfFw19k2FaVGCCFiAPvC5",
  # "H:/My Drive",
  "Michigan Zoning MAP Shared Folder",
  "MZM Data"
)

parcelzone_fields <- c("FID", "PIN", "Parcel_Jurisdiction_FIPS", "Parcel_Jurisdiction_Name", "Parcel_County_Name", "Parcel_Address", "Jurisdiction_Zone_ID", "zonecode", "isVacant", "SQFT", "geometry", "lat", "long", "Polygon_ID")

# # shouldn't have to do this. should load automatically from renv, but it doesn't
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
  "rlist",
  "purrr"
)

lapply(packages, library, character.only = TRUE)
