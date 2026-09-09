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

gdrive_root <- file.path(
  "H:/.shortcut-targets-by-id/1hw_gGJyOaJMLfFw19k2FaVGCCFiAPvC5",
  # "H:/My Drive",
  "Michigan Zoning MAP Shared Folder",
  "MZM Data"
)

parcelzone_fields <- c(
  "FID", 
  "PIN", 
  "Parcel_Jurisdiction_FIPS", 
  "Parcel_Jurisdiction_Name", 
  "Parcel_County_Name", 
  "Parcel_Address", 
  "Jurisdiction_Zone_ID", 
  "zonecode", 
  "isVacant", 
  "SQFT", 
  "geometry", 
  "lat", 
  "long", 
  "Polygon_ID"
  )

# no console output showing load success
suppressPackageStartupMessages(
  # no console output listing packages
  invisible(
    # Source - https://stackoverflow.com/a/78637925
    # Posted by vgilbart, modified by community. See post 'Timeline' for change history
    # Retrieved 2026-09-09, License - CC BY-SA 4.0
    lapply(names(renv::lockfile_read()$Packages), library, character.only = TRUE)
  )
)

