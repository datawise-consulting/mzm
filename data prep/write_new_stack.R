### pseudo-parameters for setup

# generate zone geos?
generate_zones <- T

# inherit and edit previous stack?
# inherit <- T # inherit latest stack, replacing selected geos
inherit <- file.path(proj2243_root, "data/stacks", "20260408") # inherit stack from filepath, replacing selected geos
# inherit <- F # entirely new stack

# jurisdiction parcelzones filepath
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

# output path
today <- format(Sys.Date(), "%Y%m%d")
outpath <- file.path(
  proj2243_root,
  "data/stacks",
  str_c(today, " experiment")
)

source("data prep/prep_atlas_stack.R")

# need better way to expose juri metadata
zone_attrs <- read_excel(file.path(proj2243_root, "data/MAP zones and jurisdictions/Michigan Zoning Map - Statewide Jurisdiction and Zoning Data.xlsx"))

source("data prep/prep_eligibility.R")

if (generate_zones) {
  source("data prep/prep_zone_polygons.R")
}

if (!dir.exists(outpath)) {
  dir.create(outpath)
}
st_write(
  parcel_polys,
  file.path(outpath, "parcel_geos.geojson"),
  delete_dsn = TRUE
)
write.csv(
  parcel_attrs,
  file.path(outpath, "parcel_points.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  parcelzone_oks,
  file.path(outpath, "parcel_eligibility.csv"),
  row.names = FALSE, 
  na=""
)

st_write(
  zones,
  file.path(outpath, "zone_geos.geojson"),
  delete_dsn = TRUE
)

logpath <- file.path(outpath, "log.txt")
file.create(logpath)
write_lines(x = list("inherit", inherit, "\n", "keep", keep, "\n", "exclude", exclude), file = logpath)
