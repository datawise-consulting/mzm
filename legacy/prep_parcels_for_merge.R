
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
    optparse::make_option(c("-i", "--input-file"), type = "character", default = "",
                help = "GeoJSON file to processes", metavar = "INPUT FILE"),
    optparse::make_option(c("-o", "--output-file"), type = "character", default = "",
                help = "", metavar = "OUTPUT FILE")
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


### Process data
# read input geojson
geodata <- sf::st_read(input_file)

#' Split geometries from properties, preserving linking ID fields in both.
#' Return both datasets in a list.
#'
#' @param data A data frame.
#' @param id_fields A character vector.
#' @param geo_fields A character vector.
split_properties_from_geos <- function(data, id_fields, geo_fields) {
  #keep only geo columns and parcel ID
  geos <- dplyr::select(data, all_of(c(id_fields, geo_fields)))
  # drop geo columns
  properties <- dplyr::select(data.frame(data), -one_of(geo_fields))
  return(list("geos" = geos, "properties" = properties))
}

geo_fields <- c("geometry")
datasets <- split_properties_from_geos(geodata, id_fields, geo_fields)
geos <- datasets$geos
properties <- datasets$properties

# save geos as .geojson
file_ext <- "\\.[[:alpha:]]+$"
sf::st_write(geos, 
             paste(output_path, "/", "geos_", sub(file_ext, "", output_file), ".geojson", sep=""),
             layer = "parcels",
             append = FALSE
             )
# save properties as .csv
write.csv(properties, 
          paste(output_path,"/", "properties_", sub(file_ext, "", output_file), ".csv", sep=""), 
          row.names = FALSE
          )

