test_file <- file.path(
    proj2243_root, 
    "data/data prep/QC/Macomb County/City of Memphis/City of Memphis parcelzones for QC.geojson"
)

test_path <- dirname(test_file)

test_pz <- st_read(test_file)

dissolved <- test_pz %>% group_by(Jurisdiction_Zone_ID) %>% summarize()

sf::st_write(dissolved, file.path(test_path, str_c("dissolved ", basename(test_file))))
