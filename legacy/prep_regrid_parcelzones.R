# TODO: setwd to current file so works running from SP or git repo
source("setup.R")

# TODO: figure out how to include regrid/ in path with regex
regrid_filenames <- list.files(
  path = file.path(proj2243_root, "data/county files"),
  pattern = "(mi_macomb|mi_wayne)\\.gpkg$",
  # pattern = "mi_wayne\\.gpkg$",
  recursive = TRUE,
  full.names = TRUE
)
regrid_files <- lapply(regrid_filenames, st_read)
regrid_parcels <- bind_rows(regrid_files)

cities_to_correct <- unique(regrid_parcels$scity)
write.csv(cities_to_correct, file.path(proj_root, "data/data prep/intermediate", "regrid cities to correct.csv"), row.names = FALSE)

regrid_parcelzones <- separate_longer_delim(regrid_parcels, "zoning", delim = "/")

    ### codebook - extract this into setup?
    zoning_codebook <- googlesheets4::read_sheet(
      "https://docs.google.com/spreadsheets/d/1NDQCM_JLB2lRYBLDh03IlvjwgvbxDf6Xfw41lMlOFaY",
      sheet = "Zones"
    )
    jurisdictions_codebook <- googlesheets4::read_sheet(
      "https://docs.google.com/spreadsheets/d/1NDQCM_JLB2lRYBLDh03IlvjwgvbxDf6Xfw41lMlOFaY",
      sheet = "Jurisdictions"
    )
    
    # jurisdiction_name_to_scity <- function(name) {
    #   name <- str_to_upper(name)
    #   name <- gsub("CITY OF|CHARTER ", "", name)
    #   name <- ifelse(str_detect(name, "VILLAGE OF"), paste(gsub("VILLAGE OF ", "", name), "VILLAGE"), name)
    #   return(name)
    # }
    
    zone_lookup <- zoning_codebook %>% select(any_of(
      c(
        "Jurisdiction Zone ID",
        "Jurisdiction",
        "Jurisdiction FIPS",
        "Abbreviated District Name",
        "Full District Name",
        "County"
      )
    )) %>%
      mutate(
        scity =  jurisdiction_name_to_scity(Jurisdiction)
    )
  
wc_spatial <- st_join(wc_parcelzones, regrid_parcelzones %>% select(rg.PIN = parcelnumb_no_formatting, rg.scity = scity, rg.zoning = zoning), join = st_intersects, largest = TRUE, left = TRUE)
wc_db <- merge(regrid_parcels, as.data.frame(select(wc_parcelzones, PIN, Parcel_Jurisdiction_Name, Jurisdiction_Zone_ID, zonecode)), by.x = "parcelnumb_no_formatting", by.y = "PIN", suffixes = c("", "ax"), all.x = TRUE)


ap_spatial_test <- st_join(ap_regrid, ap_parcels, join = st_intersects, largest = TRUE, left = FALSE)

########## just jotting down changes to 250 COMMON AREA parcels for later refactor into regrid prep pipeline

# TODO: figure out how to include regrid/ in path with regex
regrid_filenames <- list.files(
  path = file.path(proj2243_root, "data/county files"),
  pattern = "(mi_macomb|mi_wayne)\\.gpkg$",
  # pattern = "mi_wayne\\.gpkg$",
  recursive = TRUE,
  full.names = TRUE
)
regrid_files <- lapply(regrid_filenames, st_read)
regrid_parcels <- bind_rows(regrid_files)

regrid_parcelzones <- separate_longer_delim(regrid_parcels, "zoning", delim = "/")

common_area <- regrid_parcelzones %>% dplyr::filter(parcelnumb == "COMMON AREA") %>%
  mutate(
    FID = NA,
    PIN = gsub("-", "", ll_uuid, fixed = T),
    Parcel_Jurisdiction_FIPS = NA,
    Parcel_County_Name = "Wayne", #hardcoded for now
    Parcel_Address = str_c(address, scity, state2, szip5, sep = ", "),
    Jurisdiction_Zone_ID = NA,
    isVacant = ifelse(usps_vacancy == "N", 0, 1), # check on NAs
    SQFT = ll_gissqft,
    Polygon_ID = NA
    ) %>%
  select(
    FID,
    PIN,
    Parcel_Jurisdiction_Name = scity,
    Parcel_Jurisdiction_FIPS,
    Parcel_County_Name,
    Parcel_Address,
    Jurisdiction_Zone_ID,
    zonecode = zoning,
    isVacant,
    SQFT,
    lat,
    long = lon,
    Polygon_ID,
    geometry = wkb_geometry
  )

st_write(
  common_area,
  file.path(
    proj2243_root,
    "data/data prep",
    "QC",
    "misc",
    "common_area.geojson"
  )
)
