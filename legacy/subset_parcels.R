source("setup.R")

input_file <- file.choose()
filter_field <- readline(prompt = "enter filter field (default SITECITY): ")
if (filter_field == "") filter_field <- "SITECITY"

filter_string <- readline(prompt = "enter filter string: ")
output_file <- svDialogs::dlgSave()$res

# read input geojson
parcels <- st_read(input_file)

# filter for selected jurisdiction
filtered_parcels <- filter(parcels, .data[[filter_field]] == filter_string)

# split geometries from properties
geos <- filtered_parcels %>% select(OBJECTID_12, geometry)
properties <- filtered_parcels %>% select(!geometry)

st_write(geos, paste("geos_", output_file, sep=""))
st_write(properties, paste("properties_", output_file, sep=""))
