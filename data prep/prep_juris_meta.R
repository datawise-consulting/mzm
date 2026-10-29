state_FIPSes <- c("26")
county_FIPSes <- list(`099` = "Macomb", `125` = "Oakland", `163` = "Wayne")

# jurisdictions <- read_excel(
#   file.path(
#     proj2243_root, 
#     "data/MAP zones and jurisdictions/Michigan Zoning Map - Statewide Jurisdiction and Zoning Data.xlsx"
#     ),
#   sheet = "Jurisdictions"
#   ) 

jurisdictions <- googlesheets4::read_sheet(as_id("https://docs.google.com/spreadsheets/d/1NDQCM_JLB2lRYBLDh03IlvjwgvbxDf6Xfw41lMlOFaY"), sheet = "Jurisdictions")
jurisdictions_unpivot <- jurisdictions |>
  rename(Jurisdiction_Proper_Name = `Proper Name`, 
         Jurisdiction_Display_Name = `Jurisdiction (as entered in the NZA editor)`,
         Jurisdiction_County = `County`,
         Jurisdiction_FIPS_Code = `FIPS Code`,
         Jurisdiction_FIPS_Code_County2 = `FIPS Code (County 2)`,
         Jurisdiction_FIPS_Code_County3 = `FIPS Code (County 3)`,
         Jurisdiction_FIPS_Code_MCD = `FIPS Code (MCD container)`
         ) |>
  mutate(across(`Jurisdiction_FIPS_Code`:`Jurisdiction_FIPS_Code_County3`, as.character)) |>
  unite("Jurisdiction_FIPS_Code", Jurisdiction_FIPS_Code, Jurisdiction_FIPS_Code_County2, Jurisdiction_FIPS_Code_County3, sep = "|", na.rm = T, remove = T) |>
  tidyr::separate_longer_delim(cols = Jurisdiction_FIPS_Code, delim = "|") |>
  # look up County onto new FIPSes by digits 3-5 of FIPS
  mutate(Jurisdiction_County = lapply(Jurisdiction_FIPS_Code, function(fips) county_FIPSes[str_sub(fips, 3, 5)][[1]]))

jurisdictions_meta <- jurisdictions_unpivot |>
  select(Jurisdiction_Proper_Name, Jurisdiction_County, Jurisdiction_FIPS_Code)

