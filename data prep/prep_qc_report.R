parcel_qc <- parcel_attrs %>%
  group_by(
    Parcel_County_Name,
    Parcel_Jurisdiction_Name,
    Parcel_Jurisdiction_FIPS,
    Jurisdiction_Zone_ID
  ) %>%
  summarise(Parcel_Count = n())

# can't figure out how to get (sub)totals working well. library research?
# county_qc <- parcel_qc %>% 
#   group_by(Parcel_County_Name) %>%
#   summarise(County_Parcel_Count = sum(Parcel_Count))
# 
# juri_qc <- parcel_qc %>%
#   group_by(Parcel_County_Name, Parcel_Jurisdiction_Name) %>%
#   summarise(Juri_Parcel_Count = sum(Parcel_Count))

qc_report <- parcel_qc %>%
  # left_join(county_qc, by = join_by(Parcel_County_Name)) %>%
  # left_join(juri_qc, by = join_by(Parcel_County_Name, Parcel_Jurisdiction_Name)) %>%
  mutate(Mismatch_Type =
       ifelse(
         str_sub(Jurisdiction_Zone_ID, -3) == "000",
         "no zone",
         ifelse(
           str_sub(Jurisdiction_Zone_ID, 1, 10) != as.character(Parcel_Jurisdiction_FIPS),
           "wrong FIPS",
           NA
         )
       )
     ) %>%
  # "null" 000 JZI or JZI FIPS doesn't match juri FIPS
  dplyr::filter(!is.na(Mismatch_Type)) %>%
  select(
    Parcel_County_Name, 
    Parcel_Jurisdiction_Name, 
    Parcel_Jurisdiction_FIPS, 
    Jurisdiction_Zone_ID,
    Mismatch_Type,
    # County_Parcel_Count, 
    # Juri_Parcel_Count,
    Parcel_Count
  ) %>%
  # arrange(desc(County_Parcel_Count), desc(Juri_Parcel_Count))
  arrange(desc(Parcel_Count))
