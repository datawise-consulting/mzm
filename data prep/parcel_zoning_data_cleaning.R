### setup
packages <- c("tidyverse", "dplyr", "sf", "svDialogs", "googlesheets4", "googledrive", "stringr")
# new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
# if (length(new_packages)) {
#   install.packages(new_packages)
# }
lapply(packages, library, character.only = TRUE)

proj_root <- file.path("C:", "Users", Sys.getenv("USERNAME"), "DataWise Consulting, LLC", "DataWise SharePoint - Documents", "Projects", "2243 MAP Zoning Atlas")
setwd(proj_root)

### codebook
zoning_codebook <- googlesheets4::read_sheet(
  "https://docs.google.com/spreadsheets/d/1NDQCM_JLB2lRYBLDh03IlvjwgvbxDf6Xfw41lMlOFaY",
  sheet = "Zones"
)
jurisdictions_codebook <- googlesheets4::read_sheet(
  "https://docs.google.com/spreadsheets/d/1NDQCM_JLB2lRYBLDh03IlvjwgvbxDf6Xfw41lMlOFaY",
  sheet = "Jurisdictions"
)

zone_lookup <- zoning_codebook |> select(any_of(
  c(
    "Jurisdiction Zone ID",
    "Jurisdiction",
    "Abbreviated District Name",
    "Full District Name"
  )
))
zone_lookup$znumstr <- sapply(zone_lookup$`Jurisdiction Zone ID`, function (x) {
  str_split(x, "_")[[1]][2]
})
zone_lookup$znum <- as.integer(zone_lookup$znumstr)


### get coded zoning data from GDrive
jurisdiction_zoning_data_links <- jurisdictions_codebook |> 
  select(`Proper Name`, `GIS File Link Text`) |> 
  filter(!is.na(`GIS File Link Text`))

setwd(file.path(proj_root, "data", "zoning data from drive"))

for (j in 1:nrow(jurisdiction_zoning_data_links)) {
  skip <- FALSE
  row <- jurisdiction_zoning_data_links[j, ]
  tryCatch(
    expr = {
      file <- googledrive::drive_get(row$`GIS File Link Text`)
      if (!file.exists(row$`Proper Name`)) { dir.create(row$`Proper Name`, showWarnings = FALSE) }
      new_filename <- paste(row$`Proper Name`, "/",  row$`Proper Name`, "_parcelzones.gpkg", sep = "")
      print(paste("downloading", new_filename))
      googledrive::drive_download(file, new_filename, overwrite = TRUE)
    },
    error = function(e) { skip <<- TRUE }
    )
  if (skip) { next }
}

### read into master gpgk
coded_files <- lapply(
  lapply(
    list.files(pattern = "_parcelzones.gpkg", recursive = TRUE), st_read),
    function (x) { st_transform(x, 4267) }
)

gdrive_coded_parcelzones <- bind_rows(coded_files)

### and SharePoint
setwd(file.path(proj_root, "A Zoning Atlas for Michigan/Oakland County"))

## parcels and zones
south_lyon <- st_read("south lyon/gis/south lyon parcels coded 20251222.gpkg") |>
  mutate(tempjname = "south lyon")
milford <- st_read("milford (village)/gis/village_of_milford_zone_geos.geojson") |>
  mutate(fips = 2612553960,
         tempjname = "milford",
         `zone code` = gsub("-", "", ZONECODE))
ferndale <- st_read("ferndale/gis/Ferndale_Zoning_GIS_2025_gdb/Zoning_Parcels.shp") |>
  mutate(tempjname = "ferndale",
         `zone code` = gsub("-", "", ZONING))
# commerce <- st_read("commerce township (charter township)/gis/commerce-township_parcels.geojson") |>
#   mutate(fips = 2612517640,
#          `zone code` = gsub("-", "", EXIST_ZONE),
#          tempjname = "commerce") commerce missing zoning for ~1/3 parcels 
birmingham <- st_read("birmingham/gis/birmingham parcels recoded fixed 20251112.geojson") |>
  mutate(tempjname = "birmingham")
berkley <- st_read("berkley/gis/berkley parcels re-coded 20260128.gpkg") |>
  mutate(tempjname = "berkley")

sp_parcelzones <- lapply(
  list(south_lyon, milford, ferndale, birmingham, berkley),
  function (x) { st_transform(x, 4267) }
)
sp_parcelzones <- bind_rows(sp_parcelzones)

# missing_zones <- filter(cleaned_parcelzones, (`zone code` == "" | is.na(`zone code`)) & !grepl("\\d{10}_\\d{3}", `Jurisdiction Zone ID`, perl = TRUE))

## just zones - need to join
southfield_zones <- st_read("southfield/gis/southfield_zones.geojson") |> mutate(tempjname= "southfield")
auburn_hills <- st_read("auburn hills/gis/auburn hills zones 20260130.geojson") |> mutate(tempjname= "auburn hills")
beverly_hills <- st_read("beverly hills/gis/beverly_hills_zones.geojson") |> mutate(tempjname= "beverly hills")
bingham_farms <- st_read("bingham farms/gis/bingham_farms_zones_20250911.geojson") |> mutate(tempjname= "bingham farms")

oc_zones <- lapply(
  list(southfield_zones, auburn_hills, beverly_hills, bingham_farms),
  function (x) { st_transform(x, 4267) }
)
oc_zones <- bind_rows(oc_zones) |>
  unite(
    "zonecode",
    ZONECLASS,
    ZONECODE,
    Zoning,
    ZONEABBR,
    remove = TRUE,
    na.rm = TRUE
  ) |> select(zonecode, tempjname)
oc_parcels <- st_read(file.path(proj_root, "data/county files/Oakland County/Oakland_County_parcels.gpkg"))
oc_parcels_missing_zones <- oc_parcels |> filter(CVTTAXDESCRIPTION %in% list("CITY OF AUBURN HILLS", "CITY OF SOUTHFIELD", "VILLAGE OF BEVERLY HILLS", "VILLAGE OF BINGHAM FARMS"))
# oc_parcelzones <- st_join(st_make_valid(oc_parcels_missing_zones), st_make_valid(oc_zones), st_intersects)


### clean up and standardize. 

# fields needed for Tableau
parcel_names <- c("FID", "PIN", "Jurisdiction Zone ID", "Vacant?", "SQFT")

#fields needed for geo database
db_names <- c("FID", "county_parcel_id", "county_id", "municipality_id", "municipality_name", "municipality_label", "municipality_fips")


cleaned_parcelzones <- bind_rows(gdrive_coded_parcelzones, sp_parcelzones) |>
  unite(
    "PIN",
    PIN,
    county_parcel_id,
    KEYPIN,
    remove = TRUE,
    na.rm = TRUE
  ) |>
  mutate(
    # if PIN gets concatted to self where !is.na(PIN) & !is.na(KEYPIN)
    PIN = ifelse(str_split(PIN, "_")[[1]][1] == str_split(PIN, "_")[[1]][2], str_split(PIN, "_")[[1]][1], KEYPIN) 
  ) |>
  unite(
    "Jurisdiction Zone ID", 
    # Juris_Zone_ID, 
    # JURIS_ZONE_ID, 
    # JURIZ_ZONE_ID,
    matches("(j|J).*Z.*ID", ignore.case = FALSE),
    remove = TRUE,
    na.rm = TRUE
    ) |>
  unite(
    "CVT Jurisdiction Name",
    # CVTTAXDESCRIPTION,
    # CVTTAXDESC,
    matches("^cvttaxdesc"),
    remove = TRUE,
    na.rm = TRUE
  ) |>
  unite(
    "Notes",
    # Comment,
    # Comments,
    # COMMENTS,
    matches("^comment"),
    remove = TRUE,
    na.rm = TRUE
  ) |>
  select(any_of(parcel_names))

### relate to municipalities
municipalities <- read.csv(file.path(proj_root, "data", "data modeling", "database", "Municipalities.csv"))
cleaned_parcelzones$municipality_fips <- lapply(cleaned_parcelzones$`Jurisdiction Zone ID`, function (x) { str_split(x, "_")[[1]][1] })
cleaned_parcelzones <- merge(municipalities, cleaned_parcelzones, by = "municipality_fips", suffixes = c("", ".y")) |>
  select(names(cleaned_parcelzones), municipality_id = id) |>
  mutate(municipality_fips = NULL)



missing <- filter(cleaned_parcelzones, !grepl("\\d{10}_\\d{3}", `Jurisdiction Zone ID`, perl = TRUE))
