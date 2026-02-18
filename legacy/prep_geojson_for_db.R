source("setup.R")

####### Would like to package some of this into another module?
####### or at least a function

### Prepare for input/output
# if run or sourced from inside RStudio
if (interactive()) {
  input_file <- file.choose()

  # get output path from new file
  output_file <- svDialogs::dlg_save(
    default = basename(input_file),
    title = "Save new files as 'geos_' and 'properties_' filename"
  )$res
  if (length(output_file) == 0) {
    output_file <- input_file
  }

  # if run from CLI
} else {
  options <- list(
    optparse::make_option(c("-i", "--input-file"),
      type = "character", default = "",
      help = "GeoJSON file to processes", metavar = "INPUT FILE"
    ),
    optparse::make_option(c("-o", "--output-file"),
      type = "character", default = "",
      help = "", metavar = "OUTPUT FILE"
    )
  )
  opt_parser <- optparse::OptionParser(option_list = options)
  opt <- optparse::parse_args(opt_parser, convert_hyphens_to_underscores = TRUE)

  if (opt$input_file == "" || is.null(opt$input_file)) {
    input_file <- file.choose()
  } else {
    input_file <- opt$input_file
  }

  output_file <- ifelse(opt$output_file == "" || is.null(opt$output_file), input_file, opt$output_file)
}

output_path <- dirname(output_file)
output_file <- basename(output_file)
######

### Define table schemas
define_geo_table_schema <- function(geo_level) {
  schemas <- list(
    "county" = data.frame(
      id = numeric(),
      county_fips = numeric(),
      county_name = character(),
      county_parcel_id_field_name = character()
    ),
    "municipality" = data.frame(
      id = numeric(),
      municipality_fips = numeric(),
      municipality_name = character(),
      municipality_type = character(),
      municipality_label = character(),
      county_id = numeric()
    ),
    "parcel" = data.frame(
      id = numeric(),
      county_parcel_id = character()
    )
  )
  if (missing(geo_level)) {
    return(schemas)
  } else {
    return(schemas[[geo_level]])
  }
}

### Process data
# read input geojson
geodata <- sf::st_read(input_file)

# save geos as .geojson
file_ext <- "\\.[[:alpha:]]+$"
sf::st_write(geos,
  paste(output_path, "/", "geos_", sub(file_ext, "", output_file), ".geojson", sep = ""),
  layer = "parcels",
  append = FALSE
)
# save properties as .csv
write.csv(properties,
  paste(output_path, "/", "properties_", sub(file_ext, "", output_file), ".csv", sep = ""),
  row.names = FALSE
)
