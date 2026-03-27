#  jurisdiction parcelzones filepath
inpath <- file.path(
  proj2243_root,
  "data/data prep/QC"
)

# counties to include, not case sensitive
counties <- c(
  "macomb",
  "oakland",
  "wayne"
)

# patterns to keep, not case sensitive
keep <- c(
)

# patterns to exclude, not case sensitive
exclude <- c(
)

# juri-specific geojson files stored under `path`
juri_parcelzones_files <-
  list.files(
    path = file.path(inpath, str_c(counties, " County")),
    pattern = "parcelzones for QC\\.geojson|parcelzones\\.geojson",
    full.names = T,
    recursive = T,
    ignore.case = T
)

# `|` regex "or" operator: keep any keep, drop any exclude
selected_files <- keep(juri_parcelzones_files, grepl(paste(keep, collapse = "|"), juri_parcelzones_files, ignore.case= T))
# make sure exclude not empty. negating empty drops everything
if (length(exclude) > 0) {
  selected_files <- keep(selected_files, !grepl(paste(exclude, collapse = "|"), selected_files, ignore.case = T))
}

juri_names <- lapply(
  selected_files,
  function (x) {
    str_remove(
      str_extract(x, "([[:alnum:]]| )+parcelzones for QC") ,
      " parcelzones for QC"
      )
    }
)


# renames <- c("Jurisdiction_Zone_ID" = "Jurisdiction.Zone.ID")
## add centroids to store in files, one-time thing
## can apply other changes here, but let's not do that every time
juri_parcelzones_dfs <- map2(selected_files, juri_names, 
  ~st_read(.x) %>%
    mutate(
      # lat = st_coordinates(st_centroid(geometry))[,2],
      # long = st_coordinates(st_centroid(geometry))[,1],
      source = .y,
      SQFT = ifelse(is.na(SQFT), as.numeric(units::set_units(st_area(geometry), "ft^2")), as.numeric(SQFT)), # there must be a better way to ensure matching data types for bind_rows down below
    ) %>% 
    # rename(any_of(renames)) %>%
    select(any_of(parcelzone_fields))
)

## write each df to corresponding filepath. no need unless changes that will actually persist on disk
# lapply(
#   seq_along(juri_parcelzones_dfs),
#   function (i) {
#     st_write(juri_parcelzones_dfs[[i]], selected_files[[i]], delete_dsn = T)
#   }
# )


id_fields <- c("FID", "PIN", "Polygon_ID")
polygon_fields <- c("geometry")
attr_fields <- c(parcelzone_fields[parcelzone_fields != "geometry"], "lat", "long", "Polygon_ID")

atlas_parcelzones <- bind_rows(juri_parcelzones_dfs)
atlas_parcelzones <- atlas_parcelzones %>%
  mutate(FID = 1:nrow(atlas_parcelzones)) %>%
  group_by(geometry) %>%
  mutate(
    Polygon_ID = cur_group_id()
    )

# should default to dplyr filter but doesn't like if I don't specify
parcel_polys <- atlas_parcelzones %>% select(any_of(c(id_fields, polygon_fields))) %>% dplyr::filter(!duplicated(geometry))
parcel_attrs <- atlas_parcelzones %>% data.frame %>% select(any_of(attr_fields))

# st_write(
#   atlas_polys,
#   file.path(proj2243_root, "data/data modeling/pilot", "parcel_geos.geojson"),
#   delete_dsn = TRUE
# )
# write.csv(
#   atlas_points,
#   file.path(proj2243_root, "data/data modeling/pilot", "parcel_points.csv"),
#   row.names = FALSE,
#   na = ""
# )
