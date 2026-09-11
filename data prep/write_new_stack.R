### pseudo-parameters for setup. TODO: move to separate config file

# generate zone geos?
generate_zones <- T

# inherit and edit previous stack?
# inherit <- T # inherit latest stack, replacing selected geos
# inherit <- file.path(proj2243_root, "data/stacks", "20260511 common area wip") # inherit stack from filepath, replacing selected geos
inherit <- F # entirely new stack

# # jurisdiction parcelzones filepath
# inpath <- file.path(
#   gdrive_root,
#   "Parcels"
# )

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
  stringr::str_c(today, " common area test")
)

source("data prep/prep_atlas_stack.R")
source("data prep/prep_qc_report.R")

# need better way to expose juri metadata
if (inherit == FALSE) {
  zone_attrs_path <- file.path(proj2243_root, "data/MAP zones and jurisdictions/Michigan Zoning Map - Statewide Jurisdiction and Zoning Data.xlsx")
} else {
  zone_attrs_path <- file.path(inherit, "Michigan Zoning Map - Statewide Jurisdiction and Zoning Data.xlsx")
}
zone_attrs <- read_excel(zone_attrs_path)

source("data prep/prep_eligibility.R")

if (generate_zones) {
  source("data prep/prep_zone_polygons.R")
}

source("data prep/prep_juris_meta.R")

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
  na = "",
)
write.csv(
  parcelzone_oks,
  file.path(outpath, "parcel_eligibility.csv"),
  row.names = FALSE, 
  na = ""
)

st_write(
  zones,
  file.path(outpath, "zone_geos.geojson"),
  delete_dsn = TRUE
)

write.csv(
  qc_report,
  file.path(outpath, "qc_report.csv"),
  row.names = FALSE,
  na = ""
)

write.csv(
  data.frame(lapply(jurisdictions_unpivot, as.character), stringsAsFactors = F),
  file.path(outpath, "jurisdictions_expanded.csv"),
  row.names = FALSE,
  na = "",
  
)

file.copy(
  zone_attrs_path,
  file.path(outpath, "Michigan Zoning Map - Statewide Jurisdiction and Zoning Data.xlsx")
  )

logpath <- file.path(outpath, "log.txt")
file.create(logpath)
readr::write_lines(x = list("inherit", inherit, "\n", "keep", keep, "\n", "exclude", exclude), file = logpath)
