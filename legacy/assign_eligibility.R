source("setup.R")

parcel_attrs <- read.csv(file.path(proj_root, "data/data modeling/pilot", "parcel_points.csv"))
zone_attrs <- read_excel(file.path(proj_root, "data/MAP zones and jurisdictions/Michigan Zoning Map - Statewide Jurisdiction and Zoning Data.xlsx"))

parcelzone_fields <- c(
  "FID",
  "PIN",
  "Parcel_Jurisdiction_FIPS",
  "Parcel_Jurisdiction_Name",
  "Parcel_County_Name",
  "Parcel_Address",
  "Jurisdiction_Zone_ID",
  "zonecode",
  "isVacant",
  "SQFT",
  "geometry",
  "lat",
  "long",
  "Polygon_ID"
)
zone_attrs_clean <- zone_attrs %>% 
  rename(Jurisdiction_Zone_ID = `Jurisdiction Zone ID`) %>%
  select(any_of(parcelzone_fields), matches("Treatment"), matches("Min\\. Lot \\(SQFT\\)")) %>%
  rename_with(~ gsub(" - .*", "", .x)) %>%
  # keep wide for now
  # pivot_longer(cols = matches("Unit|SQFT"), names_to = "Attribute", values_to = "Value") %>%
    mutate(across(matches("SQFT"), 
                  # keep first value within Value only for SQFT attrs. no SQFT per unit/BR/etc
                  ~ gsub("(\\+|[[:punct:]]|[[:space:]]).*", "", .x)
                  ),
           across(everything(),
                  # if not string or number -> NA
                  ~ ifelse(!grepl("[[:alnum:]]", .x), NA, .x)
           )
    )

parcelzone_attrs <- merge(parcel_attrs, zone_attrs_clean, by = "Jurisdiction_Zone_ID", all.x = T)


# parcelzone_attrs <- map_dfc(names(zone_attrs)[names(zone_attrs) != "Jurisdiction Zone ID"], ~ parcelzone_attrs %>%
#                   mutate(!! str_c("ok", .x) := NA, .keep = "none")) %>% # need to figure out to do below ifs inside here. another map?
#     bind_cols(parcelzone_attrs, .)
# 

parcelzone_oks <- parcelzone_attrs %>%
  mutate(
   `ok1-Unit Treatment` = as.numeric(`1-Unit Treatment` == "Allowed/Conditional"),
   `ok2-Unit Treatment` = as.numeric(`2-Unit Treatment` == "Allowed/Conditional"),
   `ok3-Unit Treatment` = as.numeric(`3-Unit Treatment` == "Allowed/Conditional"),
   `ok4-Unit Treatment` = as.numeric(`4-Unit Treatment` == "Allowed/Conditional"),
   `ok5+-Unit Treatment` = as.numeric(`5+-Unit Treatment` == "Allowed/Conditional"),
   `okADU Treatment` = as.numeric(`Accessory Dwelling Unit (ADU) Treatment` == "Allowed/Conditional"),
   `ok1-Unit Min. Lot (SQFT)` = as.numeric(SQFT >= `1-Unit Min. Lot (SQFT)`),
   `ok2-Unit Min. Lot (SQFT)` = as.numeric(SQFT >= `2-Unit Min. Lot (SQFT)`),
   `ok3-Unit Min. Lot (SQFT)` = as.numeric(SQFT >= `3-Unit Min. Lot (SQFT)`),
   `ok4-Unit Min. Lot (SQFT)` = as.numeric(SQFT >= `4-Unit Min. Lot (SQFT)`),
   `ok5+-Unit Min. Lot (SQFT)` = as.numeric(SQFT >= `5+-Unit Min. Lot (SQFT)`),
   `okADU Min. Lot (SQFT)` = as.numeric(SQFT >= `ADU Min. Lot (SQFT)`),
   `ok1-Unit` = `ok1-Unit Treatment` * `ok1-Unit Min. Lot (SQFT)`,
   `ok2-Unit` = `ok2-Unit Treatment` * `ok2-Unit Min. Lot (SQFT)`,
   `ok3-Unit` = `ok3-Unit Treatment` * `ok3-Unit Min. Lot (SQFT)`,
   `ok4-Unit` = `ok4-Unit Treatment` * `ok4-Unit Min. Lot (SQFT)`,
   `ok5+-Unit` = `ok1-Unit Treatment` * `ok5+-Unit Min. Lot (SQFT)`,
   `okADU` = `okADU Treatment` * `okADU Min. Lot (SQFT)`
  ) %>%
  select(FID, PIN, matches("ok"))


# parcel_eligibility_pq <- bind_rows(
#   lapply(
#     list("Oakland", "Macomb", "Wayne"),
#     function(x) { read_excel(
#       file.path(proj_root, "data/data modeling/pilot/",
#       "parcel eligibility pq stand-in.xlsx"), 
#       sheet = paste("Parcel Eligibility (", x, ")", sep = ""))
#       }
#   )
# )

# old
# parcel_eligibility_pq <- read.csv(file.path(proj_root, "data/data modeling/pilot", "parcel_eligibility_pq.csv"))
write.csv(parcelzone_oks, file.path(proj_root, "data/data modeling/pilot", "parcel_eligibility.csv"), row.names = FALSE, na="")

