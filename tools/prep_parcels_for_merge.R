source("setup.R")

# if run or sourced from inside RStudio
if (interactive()) {
  input_file <- file.choose()
  
  filter_field  <- "SITECITY" ### <== change if necessary
  filter_string <- "BIRMINGHAM"         ### <== enter city or other value to filter by
  
  output_file <- svDialogs::dlg_save(
    default = basename(input_file), 
    title = "Save new files as 'geos_' and 'properties_' filename")$res
  if (length(output_file) == 0) {
    output_file <- input_file
  }
  
# if run from CLI
} else {
  options <- list(
    optparse::make_option(c("-i", "--input-file"), type = "character", default = "",
                help = "GeoJSON file to processes", metavar = "INPUT FILE"),
    optparse::make_option(c("-o", "--output-file"), type = "character", default = "",
                help = "", metavar = "OUTPUT FILE"),
    optparse::make_option(c("-f", "--filter_field"), type = "character", default = "SITECITY",
                help = "", metavar = "FILTER FIELD"),
    optparse::make_option(c("-s", "--filter_string"), type = "character", default = "",
                help = "", metavar = "FILTER STRING")
  )
  opt_parser <- optparse::OptionParser(option_list = options)
  opt <- optparse::parse_args(opt_parser, convert_hyphens_to_underscores = TRUE)

  if (opt$input_file == "" || is.null(opt$input_file)) {
    input_file <- file.choose()
  } else {
    input_file <- opt$input_file
  }
  filter_field <- ifelse(opt$filter_field == "", "SITECITY", opt$filter_field)
  filter_string <- opt$filter_string
  output_file <- ifelse(opt$output_file == "" || is.null(opt$output_file), input_file, opt$output_file)
  
}

output_path <- dirname(output_file)
output_file <- basename(output_file)

# read input geojson
parcels <- sf::st_read(input_file)

# filter for selected jurisdiction. empty filter string yield all features
if (filter_string == "") {
  filtered_parcels <- parcels
} else {
  filtered_parcels <- dplyr::filter(parcels, .data[[filter_field]] == filter_string)
}

# split geometries from properties
geo_columns <- c("geometry", "Shapearea", "Shapelen")
geos <- dplyr::select(filtered_parcels, all_of(c("OBJECTID_12", geo_columns)))
properties <- dplyr::select(data.frame(filtered_parcels), -one_of(geo_columns))
properties$ZONE_CODE <- ""

# save geos as .geojson
file_ext <- "\\.[[:alpha:]]+$"
sf::st_write(geos, paste(output_path, "/", "geos_", filter_string, "_", sub(file_ext, "", output_file), ".geojson", sep=""))
# save properties as .csv
write.csv(properties, 
          paste(output_path,"/", "properties_", filter_string, "_", sub(file_ext, "", output_file), ".csv", sep=""), 
          row.names = FALSE)

