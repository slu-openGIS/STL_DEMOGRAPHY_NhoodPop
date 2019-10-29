library(dplyr)
library(readr)
library(here)

# load data
pop <- read_csv(here("data", "clean", "STL_PopByNhood.csv"))
race <- read_csv(here("data", "clean", "STL_RaceByNhood.csv"))

# test 1940
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop40)
race_sub <- select(race, NHD_NUM, white40, nonwhite40)

demo40 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white40+nonwhite40) %>%
  mutate(flag = ifelse(total > pop40, TRUE, FALSE))

# test 1950
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop50)
race_sub <- select(race, NHD_NUM, white50, black50)

demo50 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white50+black50) %>%
  mutate(flag = ifelse(total > pop50, TRUE, FALSE))

# test 1960
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop60)
race_sub <- select(race, NHD_NUM, white60, black60)

demo60 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white60+black60) %>%
  mutate(flag = ifelse(total > pop60, TRUE, FALSE))

# test 1970
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop70)
race_sub <- select(race, NHD_NUM, white70, black70)

demo70 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white70+black70) %>%
  mutate(flag = ifelse(total > pop70, TRUE, FALSE))

# test 1980
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop80)
race_sub <- select(race, NHD_NUM, white80, black80)

demo80 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white80+black80) %>%
  mutate(flag = ifelse(total > pop80, TRUE, FALSE))

# test 1990
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop90)
race_sub <- select(race, NHD_NUM, white90, black90)

demo90 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white90+black90) %>%
  mutate(flag = ifelse(total > pop90, TRUE, FALSE))

# test 2000
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop00)
race_sub <- select(race, NHD_NUM, white00, black00)

demo00 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white00+black00) %>%
  mutate(flag = ifelse(total > pop00, TRUE, FALSE))

# test 2010
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop10)
race_sub <- select(race, NHD_NUM, white10, black10)

demo10 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white10+black10) %>%
  mutate(flag = ifelse(total > pop10, TRUE, FALSE))

# test 2011
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop11)
race_sub <- select(race, NHD_NUM, white11, black11)

demo11 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white11+black11) %>%
  mutate(flag = ifelse(total > pop11, TRUE, FALSE))

# test 2012
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop12)
race_sub <- select(race, NHD_NUM, white12, black12)

demo12 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white12+black12) %>%
  mutate(flag = ifelse(total > pop12, TRUE, FALSE))

# test 2013
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop13)
race_sub <- select(race, NHD_NUM, white13, black13)

demo13 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white13+black13) %>%
  mutate(flag = ifelse(total > pop13, TRUE, FALSE))

# test 2014
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop14)
race_sub <- select(race, NHD_NUM, white14, black14)

demo14 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white14+black14) %>%
  mutate(flag = ifelse(total > pop14, TRUE, FALSE))

# test 2015
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop15)
race_sub <- select(race, NHD_NUM, white15, black15)

demo15 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white15+black15) %>%
  mutate(flag = ifelse(total > pop15, TRUE, FALSE))

# test 2016
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop16)
race_sub <- select(race, NHD_NUM, white16, black16)

demo16 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white16+black16) %>%
  mutate(flag = ifelse(total > pop16, TRUE, FALSE))

# test 2016
pop_sub <- select(pop, NHD_NAME, NHD_NUM, pop17)
race_sub <- select(race, NHD_NUM, white17, black17)

demo17 <- left_join(pop_sub, race_sub, by = "NHD_NUM") %>%
  mutate(total = white17+black17) %>%
  mutate(flag = ifelse(total > pop17, TRUE, FALSE))
