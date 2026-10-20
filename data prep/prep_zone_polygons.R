sf_use_s2(FALSE)

zone_polys <- parcel_polys |> 
  select(Jurisdiction_Zone_ID, geometry) |>
  group_by(Jurisdiction_Zone_ID) |>
  st_as_sf() |>
  summarise()
  
# ca_polys <- common_area |> 
#   group_by(Jurisdiction_Zone_ID) |>
#   st_as_sf() |>
#   summarise()

zones <- merge(zone_polys, select(zone_attrs, matches("^Jurisdiction"), matches("District Name"), `Type of Zoning District`), by.x = "Jurisdiction_Zone_ID", by.y = "Jurisdiction Zone ID") |>
  mutate(across(-c(geometry), as.character))
         