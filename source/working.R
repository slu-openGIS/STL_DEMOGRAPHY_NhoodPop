
# total population
get_decennial(geography = "tract", variable = "P0010001", year = 1990, state = 29, county = 510, geometry = TRUE) %>%
  st_transform(crs = 26915) %>%
  select(GEOID, value) %>%
  rename(pop90 = value) -> pop90

# white
get_decennial(geography = "tract", variables = "P0060001", state = 29, county = 510, year = 1990, geometry = FALSE) %>%
  select(GEOID, NAME, value) %>%
  rename(white90 = value) -> white90

# black 
get_decennial(geography = "tract", variables = "P0060002", state = 29, county = 510, year = 1990, geometry = FALSE) %>% 
  select(GEOID, value) %>%
  rename(black90 = value) -> black90

# combine
stl90 <- left_join(pop90, white90, by = "GEOID") %>%
  left_join(., black90, by = "GEOID")

# interpolate to neighborhoods
st_read(here("data", "spatial", "nhood", "BND_Nhd88_cw.shp"), stringsAsFactors = FALSE) %>%
  st_transform(crs = 26915) %>%
  select(NHD_NUM) %>%
  filter(NHD_NUM <= 79) %>%
  aw_interpolate(tid = NHD_NUM, source = stl90, sid = GEOID, 
                 weight = "sum", output = "tibble", 
                 extensive = c("pop90", "white90", "black90")) %>%
  mutate(total = white90+black90) %>%
  mutate(flag = ifelse(total > pop90, TRUE, FALSE)) -> nhood90
