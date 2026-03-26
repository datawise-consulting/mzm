# output path
today <- format(Sys.Date(), "%Y%m%d")
outpath <- file.path(
  proj2243_root,
  "data/stacks",
  today
)

source("data prep/prep_atlas_stack.R")

source("data prep/prep_eligibility.R")

if (!dir.exists(outpath)) {
  dir.create(outpath)
}
st_write(
  parcel_polys,
  file.path(outpath, str_c("parcel_geos ", today, ".geojson")),
  delete_dsn = TRUE
)
write.csv(
  parcel_attrs,
  file.path(outpath, str_c("parcel_points ", today, ".csv")),
  row.names = FALSE,
  na = ""
)
write.csv(
  parcelzone_oks,
  file.path(outpath, str_c("parcel_eligibility ", today, ".csv")),
  row.names = FALSE, 
  na=""
)
