packages <- c("tidyverse",
              "sf",
              "svDialogs",
              "optparse")
new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) {
  install.packages(new_packages)
}
# lapply(packages, library, character.only=TRUE)
library(tidyverse)
library(sf)
library(svDialogs)
library(optparse)

if (interactive()) {
  # input_file <- file.choose()
  # filter_field <- readline(prompt = "enter filter field (default SITECITY): ")
  # if (filter_field == "") {
  #   filter_field <- "SITECITY"
  # }
  # filter_string <- readline(prompt = "enter filter string: ")
  # output_file <- dlgSave()$res 
  stop("Not ready yet. Please run from CLI.")
} else {
  options <- list(
    make_option(c("-i", "--input-file"), type = "character", default = "",
                help = "GeoJSON file to processes", metavar = "INPUT FILE"),
    make_option(c("-o", "--output-file"), type = "character", default = "",
                help = "", metavar = "OUTPUT FILE"),
    make_option(c("-f", "--filter_field"), type = "character", default = "SITECITY",
                help = "", metavar = "FILTER FIELD"),
    make_option(c("-s", "--filter_string"), type = "character", default = "",
                help = "", metavar = "FILTER STRING")
  )
  opt_parser <- OptionParser(option_list = options)
  opt <- parse_args(opt_parser, convert_hyphens_to_underscores = TRUE)

  if (opt$input_file == "" || is.null(opt$input_file)) {
    input_file <- file.choose()
  } else {
    input_file <- opt$input_file
  }
  filter_field <- ifelse(opt$filter_field == "", "SITECITY", opt$filter_field)
  filter_string <- opt$filter_string
  output_file <- ifelse(opt$output_file == "" || is.null(opt$output_file), basename(input_file), opt$output_file)
  
  if (length(filter_string) == 0) {
    stop()
  }
  
  # read input geojson
  parcels <- st_read(input_file)
  
  # filter for selected jurisdiction
  filtered_parcels <- filter(parcels, .data[[filter_field]] == filter_string)
  
  # split geometries from properties
  geos <- filtered_parcels %>% select(OBJECTID_12, geometry)
  properties <- filtered_parcels %>% select(!geometry)
  
  st_write(geos, paste("geos_", output_file, sep=""))
  st_write(properties, paste("properties_", output_file, sep=""))

}