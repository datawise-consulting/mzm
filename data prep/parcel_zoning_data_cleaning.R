source("setup.R")

### codebook
zoning_codebook <- googlesheets4::read_sheet(
  "https://docs.google.com/spreadsheets/d/1NDQCM_JLB2lRYBLDh03IlvjwgvbxDf6Xfw41lMlOFaY",
  sheet = "Zones"
)
jurisdictions_codebook <- googlesheets4::read_sheet(
  "https://docs.google.com/spreadsheets/d/1NDQCM_JLB2lRYBLDh03IlvjwgvbxDf6Xfw41lMlOFaY",
  sheet = "Jurisdictions"
)

zone_lookup <- zoning_codebook %>% select(any_of(
  c(
    "Jurisdiction Zone ID",
    "Jurisdiction",
    "Jurisdiction FIPS",
    "Abbreviated District Name",
    "Full District Name",
    "County"
  )
))
zone_lookup$znumstr <- sapply(zone_lookup$`Jurisdiction Zone ID`, function (x) {
  str_split(x, "_")[[1]][2]
})
zone_lookup$znum <- as.integer(zone_lookup$znumstr)


### get coded zoning data from GDrive
redownload <- FALSE

if (redownload) {
  jurisdiction_zoning_data_links <- jurisdictions_codebook %>%
    select(`Proper Name`, `GIS File Link Text`) %>%
    filter(!is.na(`GIS File Link Text`))
  
  setwd(file.path(proj_root, "data", "zoning data from drive"))
  
  for (j in 1:nrow(jurisdiction_zoning_data_links)) {
    skip <- FALSE
    row <- jurisdiction_zoning_data_links[j, ]
    tryCatch(
      expr = {
        file <- googledrive::drive_get(row$`GIS File Link Text`)
        if (!file.exists(row$`Proper Name`)) {
          dir.create(row$`Proper Name`, showWarnings = FALSE)
        }
        new_filename <- paste(row$`Proper Name`,
                              "/",
                              row$`Proper Name`,
                              "_parcelzones.gpkg",
                              sep = "")
        print(paste("downloading", new_filename))
        googledrive::drive_download(
          file,
          file.path(proj_root, "data/zoning data from drive", new_filename),
          overwrite = TRUE
        )
      },
      error = function(e) {
        skip <<- TRUE
      }
    )
    if (skip) {
      next
    }
  }
}

gdrive_files <- list.files(
  file.path(proj_root, "data/zoning data from drive"),
  pattern = "_parcelzones.gpkg",
  full.names = TRUE,
  recursive = TRUE
)
### read into master gpgk
coded_files <- lapply(lapply(gdrive_files
                             , st_read), function (x) {
                               st_transform(x, 4326)
                             })

gdrive_coded_parcelzones <- bind_rows(coded_files)

### and SharePoint
oc_jurisdictions_path <- file.path(proj_root, "A Zoning Atlas for Michigan/Oakland County")

# ## parcels and zones
# orchard_lake_village <- st_read(
#   file.path(
#     oc_jurisdictions_path,
#     "orchard lake village/gis/"
#   )
# )

rochester_hills <- st_read(
  file.path(
    oc_jurisdictions_path,
    "rochester/gis/rochester hills parcelzones.gpkg"
  )
) %>%
  mutate(tempjname = "City of Rochester Hills") %>%
  merge(
    zone_lookup,
    by.x = c("tempjname", "Zone"),
    by.y = c("Jurisdiction", "Abbreviated District Name"),
    all.x = TRUE
  )

troy <- st_read(file.path(
  oc_jurisdictions_path,
  "troy/gis/troy parcels recoded 20251112.geojson"
)) %>%
  rename(Jurisdiction_Zone_ID = Zone.ID, geom = geometry)

clawson <- st_read(file.path(
  oc_jurisdictions_path,
  "clawson/gis/clawson parcelzones.gpkg"
)) %>%
  mutate(zonecode = gsub("-", "", Zoning))

novi <- st_read(file.path(oc_jurisdictions_path, "novi/gis/novi parcelzones.gpkg")) %>%
  mutate(zonecode = gsub("-", "", ZONECLASS))

south_lyon <- st_read(
  file.path(
    oc_jurisdictions_path,
    "south lyon/gis/south lyon parcels coded 20251222.gpkg"
  )
) %>%
  mutate(tempjname = "south lyon")
milford <- st_read(
  file.path(
    oc_jurisdictions_path,
    "milford (village)/gis/milford village parcelzones.gpkg"
  )
) %>%
  mutate(
    fips = 2612553960,
    tempjname = "milford",
    `zonecode` = gsub("-", "", ZONECODE)
  )
ferndale <- st_read(
  file.path(
    oc_jurisdictions_path,
    "ferndale/gis/Ferndale_Zoning_GIS_2025_gdb/Zoning_Parcels.shp"
  )
) %>%
  mutate(tempjname = "ferndale", `zone code` = gsub("-", "", ZONING)) %>%
  rename(geom = geometry)

commerce <- st_read(
  file.path(
    oc_jurisdictions_path,
    "commerce township (charter township)/gis/commerce parcels zoned.gpkg"
  )
) %>%
  mutate(
    fips = 2612517640,
    `zone code` = gsub("-", "", EXIST_ZONE),
    tempjname = "Commerce Charter Township",
    CVTTAXDESCRIPTION = "CHARTER TOWNSHIP OF COMMERCE"
  ) %>%
  merge(
    zone_lookup,
    by.x = c("tempjname", "zone code"),
    by.y = c("Jurisdiction", "Abbreviated District Name")
  )
commerce <- st_transform(commerce, 4326)


birmingham <- st_read(
  file.path(
    oc_jurisdictions_path,
    "birmingham/gis/birmingham parcels recoded fixed 20251112.geojson"
  )
) %>%
  mutate(tempjname = "birmingham") %>%
  rename(geom = geometry)

berkley <- st_read(
  file.path(
    oc_jurisdictions_path,
    "berkley/gis/berkley parcels re-coded 20260128.gpkg"
  )
) %>%
  mutate(tempjname = "berkley") %>%
  rename(geom = geometry)

## spatially joined auburn hills, beverly hills, bingham farms, southfield
additional_parcels <- st_read(file.path(proj_root, "data/data prep/intermediate/oc parcels 4 juris zoned.gpkg"))
additional_parcels <- merge(
  additional_parcels,
  zone_lookup,
  by.x = "zonecode",
  by.y = "Abbreviated District Name",
  all.x = TRUE
)

sp_parcelzones <- lapply(list(
  rochester_hills,
  troy,
  clawson,
  commerce,
  novi,
  south_lyon,
  milford,
  ferndale,
  birmingham,
  berkley,
  additional_parcels
), function (x) {
  st_transform(x, 4326)
})
sp_parcelzones <- bind_rows(sp_parcelzones)

# oc_parcelzones <- st_read(file.path(proj_root, "data/data prep/intermediate/Oakland_County_parcelzones_coded_cleaned.gpkg"))

### clean up and standardize.

# fields needed for Tableau
parcel_names <- c(
  "FID",
  "PIN",
  "Parcel_Jurisdiction_Name",
  "Parcel_County_Name",
  "Jurisdiction_Zone_ID",
  "zonecode",
  "isVacant",
  "SQFT",
  "geom"
)

# #fields needed for geo database
# db_names <- c(
#   "OBJECTID",
#   "county_parcel_id",
#   "county_id",
#   "municipality_id",
#   "municipality_name",
#   "municipality_label",
#   "municipality_fips"
# )


oc_parcelzones <- bind_rows(gdrive_coded_parcelzones, sp_parcelzones) %>%
  unite("OBJECTID", OBJECTID_12, remove = TRUE, na.rm = TRUE) %>%
  unite("PIN",
        PIN,
        county_parcel_id,
        KEYPIN,
        remove = TRUE,
        na.rm = TRUE) %>%
  mutate(
    # FID = NA,
    # if PIN gets concatted to self where !is.na(PIN) & !is.na(KEYPIN)
    PIN = as.character(ifelse(
      str_split(PIN, "_")[[1]][1] == str_split(PIN, "_")[[1]][2],
      str_split(PIN, "_")[[1]][1],
      PIN
    )),
    Parcel_County_Name = "Oakland",
    SQFT = Shapearea,
    # units::set_units(Shapearea, "ft^2"),
    isVacant = (substr(as.character(CLASSCODE), 3, 3) == "2")
  ) %>%
  unite(
    "Jurisdiction_Zone_ID",
    # Juris_Zone_ID,
    # JURIS_ZONE_ID,
    # JURIZ_ZONE_ID,
    matches("(j|J).*Z.*ID", ignore.case = FALSE),
    remove = TRUE,
    na.rm = TRUE
  ) %>%
  mutate(
    Jurisdiction_Zone_ID = ifelse(Jurisdiction_Zone_ID %in% c("", "NA", " "), NA, Jurisdiction_Zone_ID)
  ) %>%
  unite(
    "Parcel_Jurisdiction_Name",
    # CVTTAXDESCRIPTION,
    # CVTTAXDESC,
    matches("^cvttaxdesc"),
    remove = TRUE,
    na.rm = TRUE
  ) %>%
  select(any_of(parcel_names))



gdrive_coded_parcelzones <- NULL
sp_parcelzones <- NULL
additional_parcels <- NULL

st_write(
  oc_parcelzones,
  file.path(
    proj_root,
    "data/data prep/intermediate",
    "Oakland_County_parcelzones WIP.gpkg"
  ),
  delete_layer = TRUE
)
# st_write(oc_parcelzones, file.path(proj_root, "data/data prep/intermediate", "Oakland_County_parcelzones WIP.geojson"), delete_dsn = TRUE)
oc_parcelzones <- st_read(file.path(
  proj_root,
  "data/data prep/intermediate",
  "Oakland_County_parcelzones WIP.gpkg"
))


# ## relate to municipalities. probably move to end after all counties
# municipalities <- read.csv(file.path(
#   proj_root,
#   "data",
#   "data modeling",
#   "database",
#   "Municipalities.csv"
# ))
# cleaned_parcelzones$municipality_fips <- lapply(cleaned_parcelzones$`Jurisdiction Zone ID`, function (x) {
#   str_split(x, "_")[[1]][1]
# })
# cleaned_parcelzones <- merge(municipalities,
#                              cleaned_parcelzones,
#                              by = "municipality_fips",
#                              suffixes = c("", ".y")) %>%
#   select(names(cleaned_parcelzones), municipality_id = id) %>%
#   mutate(municipality_fips = NULL)

## macomb county
mc <- st_read(
  file.path(
    proj_root,
    "data/county files/Macomb County",
    "Macomb_County_Parcel_Data.gpkg"
  )
)

# try regrid data
mc <- st_transform(st_read(
  file.path(proj_root, "data/county files/Macomb County", "mi_macomb.gpkg")
), 4326)

# new rows for parcels with multiple zones
mc_parcelzones <- separate_longer_delim(mc, zoning, delim = "/")

# mc_zone_lookup <- mc_parcelzones %>%
#   select(
#     scity, zoning, zoning_description
#   ) %>%
#   group_by(
#     scity, zoning, zoning_description
#   ) %>%
#   summarise()

# manually cleaned in Excel the above
mc_zone_lookup <- readxl::read_excel(file.path(proj_root, "data/data prep/intermediate", "mc zones mismatch 20260204.xlsx"))

mc_parcelzones <- st_sf(merge(mc_parcelzones, mc_zone_lookup, by = c("zoning", "scity"))) %>%
  mutate(
    # FID = NA,
    PIN = parcelnumb_no_formatting,
    Parcel_Jurisdiction_Name = scity,
    Parcel_County_Name = "Macomb",
    Jurisdiction_Zone_ID = `Jurisdiction Zone ID`,
    OBJECTID = ll_uuid,
    #ogc_fid, not included in download? could prob just be numeric index but err on side of caution
    zonecode = `cleaned to`,
    SQFT = as.numeric(units::set_units(ll_gissqft, "ft^2")),
    isVacant = ifelse(usps_vacancy == "N", 0, 1) # check on NAs
  ) %>%
  rename(geom = wkb_geometry) %>%
  mutate(
    Jurisdiction_Zone_ID = ifelse(Jurisdiction_Zone_ID %in% c("", "NA", " "), NA, Jurisdiction_Zone_ID)
  ) %>%
  select(any_of(parcel_names))

st_write(
  mc_parcelzones,
  file.path(
    proj_root,
    "data/data prep/intermediate",
    "Macomb_County_parcelzones WIP.gpkg"
  ),
  delete_layer = TRUE
)
mc_parcelzones <- st_read(file.path(
  proj_root,
  "data/data prep/intermediate",
  "Macomb_County_parcelzones WIP.gpkg"
))

## wayne county
wc_parcels <- st_transform(st_read(
  file.path(
    proj_root,
    "data/county files/Wayne County",
    "Wayne_County_parcels_located.gpkg"
  )
), 4326)

wc_juris_files <- list.files(
  file.path(
    proj_root,
    "data/county files/Wayne County/Municipal Assessment"
  ),
  "*.csv",
  recursive = TRUE,
  full.names = TRUE
)

wc_juris <- wc_juris_files %>% map_df( ~ {
  read_csv(.x, show_col_types = FALSE) %>%
    mutate(across(everything(), as.character)) %>%
    mutate(AssessmentCity = gsub(
      "Municipal Assessment|[[:punct:]]",
      "",
      str_extract(.x, "Municipal Assessment/([[:alpha:]]|_| )*")
    ))
  #, "Municipal Assessment|\\/"))
}) %>% bind_rows %>%
  mutate(Parcels.pnum = gsub(" ", "", Parcels.pnum))
wc_parcelzones <- merge(wc_parcels,
                        wc_juris,
                        by.x = "packedParc",
                        by.y = "Parcels.pnum",
                        all.x = TRUE)


# wc_parcelzone_jurisdictions <- wc_parcelzones %>% select(
#   packedParc,
#   `Jurisdiction from parcels` = propcity,
#   `Jurisdiction from parcel assessment` = ParcelMaster.propcity,
#   `Jurisdiction from parcel assessment dir` = AssessmentCity,
#   `Jurisdiction from spatial` = Label,
#   FIPSCode
# ) %>%
#   mutate(
#   `Jurisdiction FIPS from spatial` = ifelse(is.na(FIPSCode), NA, paste("26163", FIPSCode, sep = "")),
#   FIPSCode = NULL,
#   `Missing geom` = st_is_empty(geom)
#   )
# wc_parcelzone_jurisdictions <- merge(
#   wc_parcelzone_jurisdictions,
#   select(jurisdictions_codebook, `Proper Name`, `FIPS Code`),
#   by.x = "Jurisdiction FIPS from spatial", by.y = "FIPS Code",
#   all.x = TRUE) %>%
#   rename(
#     `Proper Name from codebook` = `Proper Name`
#   )
#
# wc_parcels_missing_parcel_info <- wc_parcelzone_jurisdictions %>% filter(is.na(packedParc))
# wc_parcels_missing_jurisdictions <- wc_parcelzone_jurisdictions %>% filter(is.na(`Jurisdiction from spatial`))

# # patch up Jurisdictions
# wc_parcelzones_fix_juris <- wc_parcelzones %>% mutate(
#   Jurisdiction_propcity = propcity,
#   Jurisdiction_ParcelMaster.propcity = ParcelMaster.propcity,
#   Jurisdiction_assessment = str_to_upper(AssessmentCity),
#   Jurisdiction_spatial = str_to_upper(gsub("city of|charter ", "", str_to_lower(Label)))
# ) %>%
#   select(
#     packedParc,
#     starts_with("Jurisdiction_")
#   )
# 
# assessment_file_name_doesnt_match <- wc_parcelzones_fix_juris %>%
#   filter(Jurisdiction_propcity != Jurisdiction_assessment & Jurisdiction_ParcelMaster.propcity != Jurisdiction_assessment)

wc_parcelzones_with_FIPS <- wc_parcelzones %>%
  filter(!is.na(FIPSCode))
wc_parcelzones_no_FIPS <- wc_parcelzones %>%
  filter(is.na(FIPSCode)) %>%
  inner_join(y = mutate(select(jurisdictions_codebook, `FIPS Code`, `Proper Name`), `Proper Name` = gsub("charter ", "", `Proper Name`, ignore.case = TRUE)), join_by(New.Name == `Proper Name`), keep = TRUE)

wc_parcelzones <- bind_rows(wc_parcelzones_with_FIPS, wc_parcelzones_no_FIPS) %>% 
  mutate(
    FIPSCode = ifelse(!is.na(FIPSCode), paste("26163", FIPSCode, sep = ""), NA)
  ) %>%
  unite(
    "Jurisdiction_FIPS_Code",
    FIPSCode,
    `FIPS Code`,
    remove = TRUE,
    na.rm = TRUE
  )

# clean up Wayne zones
wc_parcelzones_zones_to_clean <- wc_parcelzones %>% 
  separate_longer_delim(cols = ParcelMaster.zoning, delim = "/") %>%
  select(New.Name, Jurisdiction_FIPS_Code, ParcelMaster.zoning) %>%
  group_by(New.Name, Jurisdiction_FIPS_Code, ParcelMaster.zoning) %>%
  summarise() %>% data.frame # %>% select(!(geom))

write.csv(wc_parcelzones_zones_to_clean, file.path(proj_root, "data/data prep/intermediate/wc_parcelzones_to_clean.csv"), row.names = FALSE)

wayne_zoning_cleanup <- read_excel(file.path(proj_root, "data/data prep/intermediate", "wc_parcelzones_to_clean.xlsx")) %>%
  select(Jurisdiction_FIPS_Code, ParcelMaster.zoning, `cleaned zonecode`, `lookup zone id`)

wc_parcelzones %<>% merge(y = wayne_zoning_cleanup, by = c("Jurisdiction_FIPS_Code", "ParcelMaster.zoning"))


# # zoning codebook
# wayne_zone_lookup <- zone_lookup %>%
#   filter(County == "Wayne")
# wayne_zoneids <- merge(
#   wc_parcelzones,
#   wayne_zone_lookup,
#   by.x = c("FIPSCode", "ParcelMaster.zoning"),
#   by.y = c("Jurisdiction FIPS", "Abbreviated District Name"),
#   all.x
# )

# combine this into one pipe with oc and mc later
wc_parcelzones <- wc_parcelzones %>%
  rename(
    # FID = NA,
    PIN = packedParc,
    Parcel_Jurisdiction_Name = New.Name,
    zonecode = `cleaned zonecode`,
    Jurisdiction_Zone_ID = `lookup zone id`
  ) %>%
  mutate(
    geom = st_make_valid(geom),
    SQFT = as.numeric(units::set_units(st_area(geom), "ft^2")),
    isVacant = as.integer(ParcelMaster.vacant),
    OBJECTID = NA,
    Parcel_County_Name = "Wayne"
  ) %>%
  mutate(
    Jurisdiction_Zone_ID = ifelse(Jurisdiction_Zone_ID %in% c("", "NA", " "), NA, Jurisdiction_Zone_ID)
  ) %>%
  select(any_of(parcel_names))

wc_parcels <- NULL
wc_juris <- NULL
wc_juris_fixed <- NULL
wc_juris_bound <- NULL


st_write(
  wc_parcelzones,
  file.path(
    proj_root,
    "data/data prep/intermediate",
    "Wayne_County_parcelzones WIP.gpkg"
  ),
  delete_layer = TRUE
)
wc_parcelzones <- st_read(file.path(
  proj_root,
  "data/data prep/intermediate",
  "Wayne_County_parcelzones WIP.gpkg"
))

### combine into master file
pilot_parcelzones <-  bind_rows(oc_parcelzones, mc_parcelzones, wc_parcelzones) 
pilot_parcelzones %<>% 
  mutate(geom = st_make_valid(geom)) %>%
  filter(st_is_valid(geom) == TRUE)
pilot_parcelzones %<>%
  mutate(
    FID = 1:nrow(.),
    zonecode = ifelse(zonecode == " ", NA, zonecode),
    Jurisdiction_Zone_ID = ifelse(Jurisdiction_Zone_ID %in% c("", "NA", " "), NA, Jurisdiction_Zone_ID),
    Parcel_Jurisdiction_Name = str_to_upper(Parcel_Jurisdiction_Name)
  )

oc_parcelzones <- NULL
mc_parcelzones <- NULL
wc_parcelzones <- NULL

pilot_parcelzones$Centroid <- st_centroid(pilot_parcelzones$geom)
pilot_parcelzones %<>% 
  mutate(
    long = st_coordinates(Centroid)[,1],
    lat = st_coordinates(Centroid)[,2]
    )


# split for Tableau
id_fields <- c("FID")
polygon_fields <- c("geom")
attr_fields <- c(parcel_names[parcel_names != "geom"], "lat", "long")


pilot_geos <- pilot_parcelzones %>% select(any_of(c(id_fields, polygon_fields)))
pilot_attrs <- select(data.frame(pilot_parcelzones), any_of(attr_fields))

pilot_parcelzones <- NULL

st_write(
  pilot_geos,
  file.path(proj_root, "data/data modeling/pilot", "parcel_geos.geojson"),
  delete_dsn = TRUE
)
write.csv(
  pilot_attrs,
  file.path(proj_root, "data/data modeling/pilot", "parcel_points.csv"),
  row.names = FALSE
)

pilot_geos <- NULL
pilot_attrs <- NULL
