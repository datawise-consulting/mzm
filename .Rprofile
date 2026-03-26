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

# shouldn't have to do this. should load automatically from renv, but it doesn't
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
