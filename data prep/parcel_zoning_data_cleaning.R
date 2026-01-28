### setup
packages <- c("tidyverse", "dplyr", "sf", "svDialogs", "googlesheets4", "stringr")
new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
if (length(new_packages)) {
  install.packages(new_packages)
}
lapply(new_packages, library, character.only = TRUE)

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
    "Abbreviated District Name"
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

setwd(file.path("data", "zoning data from drive"))

for (j in 1:nrow(jurisdiction_zoning_data_links)) {
  skip <- FALSE
  row <- jurisdiction_zoning_data_links[j, ]
  tryCatch(
    expr = {
      file <- googledrive::drive_get(row$`GIS File Link Text`)
      if (!file.exists(row$`Proper Name`)) { dir.create(row$`Proper Name`, showWarnings = FALSE) }
      new_filename <- paste(row$`Proper Name`, "/",  row$`Proper Name`, "_parcelzones.gpkg", sep = "")
      print(paste("downloading", new_filename))
      googledrive::drive_download(file, new_filename)
    },
    error = function(e) { skip <<- TRUE }
    )
  if (skip) { next }
}

### read into master gpgk
coded_files <- lapply(
  lapply(list.files(pattern = "_parcelzones.gpkg", recursive = TRUE), st_read),
  function (x) { st_transform(x, 4267) }
)
coded_parcelzones <- bind_rows(coded_files)

### assign zones
# zoning_code_numstr <- coded_parcelzones |> filter(!is.na(Zoning_Code) & !is.na(as.integer(Zoning_Code)))
# zoning_code_numstr <- merge(zoning_code_numstr, zone_lookup, by.x = "Zoning_Code", by.y = "znumstr")
# 
# zoning_code_str <- coded_parcelzones |> filter(grepl("[[:alpha:]]", Zoning_Code))
# zoning_code_str <- merge(zoning_code_str, zone_lookup, by.x = "Zoning_Code", by.y = "Abbreviated District Name")
# 
# zone_code_str <- coded_parcelzones |> filter(!is.na(ZONE_CODE) & !grepl("[[:lower:]]", ZONE_CODE))

### clean up and standardize
parcel_names <- c("OBJECTID_12", "PIN", "municipality_id", "Jurisdiction Zone ID", "county_id")

cleaned_parcelzones <- coded_parcelzones |>
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
    Juris_Zone_ID, 
    JURIS_ZONE_ID, 
    JURIZ_ZONE_ID,
    remove = TRUE,
    na.rm = TRUE
    ) |>
  unite(
    "CVT Jurisdiction Name",
    CVTTAXDESCRIPTION,
    CVTTAXDESC,
    remove = TRUE,
    na.rm = TRUE
  ) |>
  unite(
    "Notes",
    Comment,
    Comments,
    COMMENTS,
    remove = TRUE,
    na.rm = TRUE
  ) |>
  select(any_of(parcel_names))

# # separate groups for inconsistent zone codes
# dfs <- cleaned_parcelzones |>
#   unite(
#     "Zoning Code",
#     Zoning_Code,
#     ZONE_CODE,
#     remove = TRUE,
#     na.rm = TRUE
#   ) |>
#   mutate(
#     zcode_type = ifelse(is.na(as.integer(`Zoning Code`)), "str", "int")
#   ) |>
#   group_by(zcode_type) |>
#   group_split()
# numzcode <- dfs[[1]]
# strzcode <- dfs[[2]]
# 
# numzcode <- merge(numzcode, zone_lookup, by = "Jurisdiction Zone ID", suffixes = c("", "y"))
# numzcode_recoded <- numzcode |> 
#   select(names(numzcode), zcodetemp  = `Abbreviated District Name`) |>
#   mutate(
#     `Zoning Code` = zcodetemp,
#     zcodetemp = NULL
#   )
# 
# numzcode <- numzcode_recoded |> select(any_of(parcel_names))
# strzcode <- strzcode |> select(any_of(parcel_names))
# cleaned_parcelzones <- rbind(numzcode, strzcode)


# # missing FIPS codes -> Jurisdiction Zone IDs
# dfs <- cleaned_parcelzones |> 
#   mutate(missing_jzi = !grepl("\\d{10}_\\d{3}", `Jurisdiction Zone ID`, perl = TRUE)) |> 
#   group_by(missing_jzi) |> 
#   group_split()
# not_missing <- dfs[[1]]
# missing <- dfs[[2]]
# 
# municipalities <- read.csv(file.path("data", "data modeling", "database", "Municipalities.csv"))
# municipality_label_to_cvttaxdesc <- function (string) {
#   result <- gsub("Township", "Township of", string, fixed = TRUE)
#   result <- paste(str_extract(result, "\\(.*?\\)"), " ", str_split(result, " \\(")[[1]][1], sep = "")
#   result <- gsub("\\(|\\)", "", result)
#   result <- str_to_upper(result)
#   return(result)
# }
# municipalities$`CVT Jurisdiction Name` <- lapply(municipalities$municipality_label, municipality_label_to_cvttaxdesc)
# added_fips <- merge(missing, municipalities, by = "CVT Jurisdiction Name", suffixes = c("x", ""))
# added_fips <- added_fips |> select(names(missing), municipality_fips)
# dfs$missing <- merge(dfs$missing, zone_lookup, by.x = "ZONE_CODE", by.y = "Abbreviated District Name")



