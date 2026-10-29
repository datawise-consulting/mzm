### pseudo-parameters for setup. TODO: move to separate config file

# generate zone geos?
generate_zones <- F

# inherit and edit previous stack?
# inherit <- T # inherit latest stack, replacing selected geos
# inherit <- file.path(gdrive_root, "MZM Data/Model", "20260807") # inherit stack from filepath, replacing selected geos
inherit <- F # entirely new stack

## Shared GDrive path
# jurisdiction parcelzones filepath
inpath <- file.path(
  gdrive_root,
  "MZM Data/Parcels"
)

## DW SharePoint path
# inpath <- file.path(
#   proj2243_root,
#   "data/data prep/QC"
# )

# counties to include, not case sensitive
# TODO: read from inpath to view available counties
counties <- c(
  "macomb",
  "oakland",
  "wayne"
)

# patterns to keep, not case sensitive
keep <- c(
  "addison"
)

# patterns to exclude, not case sensitive
exclude <- c(
)


# output path
today <- format(Sys.Date(), "%Y%m%d")
dest_folder_name <- paste(
  today
  , "codebook copy test"
)

# empty temporary output folder after stack run?
clear_temp_output <- T

# outpath <- file.path(
#   proj2243_root,
#   "data/stacks",
#   dest_folder_name
# )

## write to temp path before upload. can't copy gsheet directly for some reason
temp_path <- file.path(user_root, "temp")
if (!dir.exists(temp_path)) {
  dir.create(temp_path)
}

outpath_parent <- file.path(temp_path, "mzm_outputs")
if (!dir.exists(outpath_parent)) {
  dir.create(outpath_parent)
}

outpath <- file.path(outpath_parent, dest_folder_name)
if (!dir.exists(outpath)) {
  dir.create(outpath_parent)
}

# outpath <- file.path(
#   gdrive_root,
#   "MZM Data/Model",
#   dest_folder_name
# )

# Michigan Zoning MAP Shared Folder\MZM Data\Model
drivepath <- googledrive::as_id("https://drive.google.com/drive/u/0/folders/14xdVn0mFOBq9QO6ZgGRZDGwW89eI6VjB")

source("data prep/prep_atlas_stack.R")
# source("data prep/prep_qc_report.R")

# need stable filepath if not inheriting; proj2243_root will not work on MAP computers
# if (inherit == FALSE) {
  # zone_attrs_path <- file.path(proj2243_root, "data/MAP zones and jurisdictions/Michigan Zoning Map - Statewide Jurisdiction and Zoning Data.xlsx")

# use the same live codebook for everything currently. 
# having trouble reading from gdrive paths to get files dynamically.
# could read locally, but only works for Excel not .gsheet
codebook <- googledrive::as_id("https://docs.google.com/spreadsheets/d/1NDQCM_JLB2lRYBLDh03IlvjwgvbxDf6Xfw41lMlOFaY")
zone_attrs <- googlesheets4::read_sheet(codebook)
# } else {
#   # zone_attrs_path <- file.path(inherit, "Michigan Zoning Map - Statewide Jurisdiction and Zoning Data.xlsx")
#   prev_codebook <- 
# }
# zone_attrs <- read_excel(zone_attrs_path)

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

if (generate_zones == T) {
  st_write(
    zones,
    file.path(outpath, "zone_geos.geojson"),
    delete_dsn = TRUE
  )
}
  
write.csv(
  data.frame(lapply(jurisdictions_unpivot, as.character), stringsAsFactors = F),
  file.path(outpath, "jurisdictions_expanded.csv"),
  row.names = FALSE,
  na = "",
  
)

# copy mostly static geospatial files necessary for polygons in Tableau
if (inherit == F) {
  copy_path <- file.path(gdrive_root, "State Wide")
} else (
  copy_path <- inherit
)
copy_files <- list.files(copy_path, full.names = TRUE, ignore.case = TRUE)
# can't copy gsheet over normally. use `drive_cp`
copy_files <- purrr::keep(copy_files, !grepl(x = copy_files, pattern = "Michigan Zoning Map - Statewide Jurisdiction and Zoning Data.gsheet"))
lapply(copy_files, function (x) { file.copy(x, outpath) })


logpath <- file.path(outpath, "log.txt")
file.create(logpath)
readr::write_lines(x = list("inherit", inherit, "\n", "keep", keep, "\n", "exclude", exclude), file = logpath)

# ## upload to gdrive
stack_files <- list.files(outpath, full.names = TRUE)
new_stack_folder <- googledrive::drive_mkdir(dest_folder_name, drivepath)
drive_cp(codebook, new_stack_folder, name = "Michigan Zoning Map - Statewide Jurisdiction and Zoning Data")
lapply(stack_files, function (x) { drive_upload(x, path = new_stack_folder) })

if (clear_temp_output) {
  dir_delete(outpath)
}

