# juri-specific geojson files stored under `path`
juri_parcelzones_files <-
  list.files(
    path = file.path(inpath, str_c(counties, " County")),
    pattern = "parcelzones for QC\\.geojson|parcelzones\\.geojson",
    full.names = T,
    recursive = T,
    ignore.case = T
)

# if inheriting, only read in specified files
if (inherit == F || length(keep) > 0) {
  # `|` regex "or" operator: keep any keep, drop any exclude
  selected_files <- keep(juri_parcelzones_files, grepl(paste(keep, collapse = "|"), juri_parcelzones_files, ignore.case= T))
  # make sure exclude not empty. negating empty drops everything
  if (length(exclude) > 0) {
    selected_files <- keep(selected_files, !grepl(paste(exclude, collapse = "|"), selected_files, ignore.case = T))
  }
} else {
  selected_files <- list()
}


# todo: parameterize this
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

stitch_stack <- function(polys_path, points_path, join_field = "FID") {
  polys <- st_read(polys_path)
  points <- read.csv(points_path)
  stack <- merge(points, select(polys, any_of(join_field), any_of("geometry")), by = join_field)
  return(stack)
}

if (inherit == T) {
  stack_paths <- list.dirs(
    file.path(proj2243_root, "data/stacks"),
    full.names = T,
    recursive = F
  )
  # this is useful. wrap into function later
  filesdf <- cbind(
    path = stack_paths,
    stamptime = format(as.Date(str_sub(basename(stack_paths), 1, 8), format = "%Y%m%d"), "%Y%m%d"),
    mtime = format(as.POSIXct(file.mtime(stack_paths)), "%Y%m%d%H%M")
  ) %>% data.frame
  # narrow by DW-standard timestamp first, then by modified date if tied
  latest <- filesdf %>% dplyr::filter(stamptime == max(stamptime)) %>% dplyr::filter(mtime == max(mtime))
  inherit <- latest$path[[1]]
  prev_stack <- stitch_stack(
    file.path(inherit, "parcel_geos.geojson"),
    file.path(inherit, "parcel_points.csv")
  )
} else if (is.character(inherit)) {
  if (dir.exists(inherit)) {
    prev_stack <- stitch_stack(
      file.path(inherit, "parcel_geos.geojson"),
      file.path(inherit, "parcel_points.csv")
    )
  } else {
    stop("path to stack not found")
  }
} else if (inherit == F) {
  prev_stack <- data.frame()
}

new_parcelzones <- bind_rows(juri_parcelzones_dfs)

if (nrow(prev_stack) > 0) {
  # coerce all columns to text for easy append. 
  # probably preferable to predetermine and enforce types, 
  # but most type changes won't survive being written to disk anyway
  prev_stack <- prev_stack %>% mutate(across(!any_of("geometry"), as.character))
  if (nrow(new_parcelzones) > 0) {
    new_parcelzones <- new_parcelzones %>% mutate(across(!any_of("geometry"), as.character))
    atlas_parcelzones <- prev_stack %>% anti_join(new_parcelzones, by = "PIN")
    atlas_parcelzones <- bind_rows(atlas_parcelzones, new_parcelzones)
  } else {
    atlas_parcelzones <- prev_stack
  }
} else {
  atlas_parcelzones <- new_parcelzones
}

atlas_parcelzones <- atlas_parcelzones %>%
  mutate(FID = 1:nrow(atlas_parcelzones)) %>%
  group_by(geometry) %>%
  mutate(
    Polygon_ID = cur_group_id()
    )

# should default to dplyr filter but doesn't like if I don't specify
parcel_polys <- atlas_parcelzones %>% select(any_of(c(id_fields, polygon_fields))) %>% dplyr::filter(!duplicated(geometry))
parcel_attrs <- atlas_parcelzones %>% data.frame %>% select(any_of(attr_fields))
