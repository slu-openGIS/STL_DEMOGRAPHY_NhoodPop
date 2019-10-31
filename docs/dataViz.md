Data Visualizations
================
Christopher Prener, Ph.D., Carter Hanford, B.A.
(October 31, 2019)

## Introduction

This notebook generates a number of data visualizations, primarily maps,
based on the neighborhood population and race estimates.

## Dependencies

This notebook requires a number of different `R` packages:

``` r
# tidyverse packages
library(dplyr)         # data wrangling
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` r
library(readr)         # working with csv data
library(ggplot2)       # mapping
```

    ## Registered S3 methods overwritten by 'ggplot2':
    ##   method         from 
    ##   [.quosures     rlang
    ##   c.quosures     rlang
    ##   print.quosures rlang

``` r
# spatial packages
library(sf)            # working with spatial data
```

    ## Linking to GEOS 3.6.1, GDAL 2.1.3, PROJ 4.9.3

``` r
# other packages
library(here)          # file path management
```

    ## here() starts at /Users/prenercg/GitHub/STL_DEMOGRAPHY_NhoodPop

``` r
library(measurements)  # unit converting
```

## Load Source

Here we will load necessary functions for formatting the neighborhood
maps and saving them into our results folder.

``` r
source(here("source", "cp_sequoiaTheme.R"))
source(here("source", "cp_plotSave.R"))
```

## Load Data

In this section, we’ll be using the STL Population and Race data by
neighborhood located in the clean folder under data.

``` r
# total population
pop <- read_csv(here("data", "clean", "STL_PopByNhood.csv"))
```

    ## Parsed with column specification:
    ## cols(
    ##   .default = col_double(),
    ##   NHD_NAME = col_character()
    ## )

    ## See spec(...) for full column specifications.

``` r
# race
race <- read_csv(here("data", "clean", "STL_RaceByNhood.csv"))
```

    ## Parsed with column specification:
    ## cols(
    ##   .default = col_double(),
    ##   NHD_NAME = col_character()
    ## )
    ## See spec(...) for full column specifications.

``` r
# neighborhood boundaries
st_read(here("data", "spatial", "nhood", "BND_Nhd88_cw.shp"), 
                    stringsAsFactors = FALSE) %>%
  st_transform(crs = 26915) %>%
  select(NHD_NUM) -> nhood_sf
```

    ## Reading layer `BND_Nhd88_cw' from data source `/Users/prenercg/GitHub/STL_DEMOGRAPHY_NhoodPop/data/spatial/nhood/BND_Nhd88_cw.shp' using driver `ESRI Shapefile'
    ## Simple feature collection with 88 features and 6 fields
    ## geometry type:  MULTIPOLYGON
    ## dimension:      XY
    ## bbox:           xmin: 871512.3 ymin: 982994.4 xmax: 912850.5 ymax: 1070957
    ## epsg (SRID):    NA
    ## proj4string:    +proj=tmerc +lat_0=35.83333333333334 +lon_0=-90.5 +k=0.9999333333333333 +x_0=250000 +y_0=0 +datum=NAD83 +units=us-ft +no_defs

## Merge STL Pop/Race

To generate the appropriate maps, we need to merge the STL population
and race by neighborhood data in the clean folder. The join turns
generates spatial data that we can map to the city of St. Louis.

``` r
# remove excess column
race <- select(race, -NHD_NAME)

# combine
nhood <- left_join(pop, race, by = "NHD_NUM")
nhood <- left_join(nhood_sf, nhood, by = "NHD_NUM") %>%
  filter(NHD_NUM < 80)
```

Next, for formatting purposes, we need to convert from m^2 to km^2:

``` r
nhood %>%
  mutate(sqmi = unclass(st_area(geometry))) %>%
  mutate(sqmi = conv_unit(sqmi, from = "m2", to = "mi2")) -> nhood
```

## Maps - Neighborhoods by Race

Now that we have our spatial data formatted and ready to go, we can
start to map the neighborhoods by year. Using `ggplot`, we’ll generate
racial composition maps of St. Louis neighborhoods. Starting in 1940, we
will generate 15 separate maps, 1940-2010 (decennial), and 2011-2017.
This section will be lengthy and will use recycled code from the first
block, so we’ll refrain from narrative.

### 1940

First, we’ll map the population density of neighborhoods in 1940:

``` r
nhood <- mutate(nhood, den = pop40/sqmi)
min <- round(min(nhood$den), 0)
max <- round(max(nhood$den), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+1
breaks[5] <- breaks[5]-1

plot_den <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = den), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "OrRd", name = "Population\nper Sq. Mi.", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Population Density, 1940",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via NHGIS and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)
```

Next, we’ll map the percentage of each neighborhood’s population that
was not white. A quick note, census data from 1940 does not have a
`black` percentage, so we will use `non-white`.

``` r
nhood <- mutate(nhood, pct = (nonwhite40/pop40)*100)
min <- round(min(nhood$pct), 0)
max <- round(max(nhood$pct), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+.1
breaks[5] <- breaks[5]-.1

plot_race <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = pct), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "RdPu", name = "% Non-white", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Percent Non-white, 1940",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via NHGIS and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)
```

Finally, we’ll save both
maps:

``` r
cp_plotSave(here("results", "Map_PctBlack", "map_1940_nonwhite.png"), plot_race, preset = "lg", dpi = 500)
cp_plotSave(here("results", "Map_PopDensity", "map_1940_pop_density.png"), plot_den, preset = "lg", dpi = 500)
```

### 1950

We’ll repeat the same code for 1950:

``` r
# population density
nhood <- mutate(nhood, den = pop50/sqmi)
min <- round(min(nhood$den), 0)
max <- round(max(nhood$den), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+1
breaks[5] <- breaks[5]-1

plot_den <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = den), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "OrRd", name = "Population\nper Sq. Mi.", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Population Density, 1950",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via NHGIS and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# race
nhood <- mutate(nhood, pct = (black50/pop50)*100)
min <- round(min(nhood$pct), 0)
max <- round(max(nhood$pct), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+.1
breaks[5] <- breaks[5]-.1

plot_race <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = pct), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "RdPu", name = "% African American", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Percent Black, 1950",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via NHGIS and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# save
cp_plotSave(here("results", "Map_PctBlack", "map_1950_black.png"), plot_race, preset = "lg", dpi = 500)
cp_plotSave(here("results", "Map_PopDensity", "map_1950_pop_density.png"), plot_den, preset = "lg", dpi = 500)
```

### 1960

We’ll repeat the same code for 1960:

``` r
# population density
nhood <- mutate(nhood, den = pop60/sqmi)
min <- round(min(nhood$den), 0)
max <- round(max(nhood$den), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+1
breaks[5] <- breaks[5]-1

plot_den <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = den), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "OrRd", name = "Population\nper Sq. Mi.", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Population Density, 1960",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via NHGIS and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# race
nhood <- mutate(nhood, pct = (black60/pop60)*100)
min <- round(min(nhood$pct), 0)
max <- round(max(nhood$pct), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+.1
breaks[5] <- breaks[5]-.3

plot_race <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = pct), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "RdPu", name = "% African American", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Percent Black, 1960",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via NHGIS and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# save
cp_plotSave(here("results", "Map_PctBlack", "map_1960_black.png"), plot_race, preset = "lg", dpi = 500)
cp_plotSave(here("results", "Map_PopDensity", "map_1960_pop_density.png"), plot_den, preset = "lg", dpi = 500)
```

### 1970

We’ll repeat the same code for 1970:

``` r
# population density
nhood <- mutate(nhood, den = pop70/sqmi)
min <- round(min(nhood$den), 0)
max <- round(max(nhood$den), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+1
breaks[5] <- breaks[5]-1

plot_den <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = den), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "OrRd", name = "Population\nper Sq. Mi.", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Population Density, 1970",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via NHGIS and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# race
nhood <- mutate(nhood, pct = (black70/pop70)*100)
min <- round(min(nhood$pct), 0)
max <- round(max(nhood$pct), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+.1
breaks[5] <- breaks[5]-.1

plot_race <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = pct), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "RdPu", name = "% African American", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Percent Black, 1970",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via NHGIS and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# save
cp_plotSave(here("results", "Map_PctBlack", "map_1970_black.png"), plot_race, preset = "lg", dpi = 500)
cp_plotSave(here("results", "Map_PopDensity", "map_1970_pop_density.png"), plot_den, preset = "lg", dpi = 500)
```

### 1980

We’ll repeat the same code for 1980:

``` r
# population density
nhood <- mutate(nhood, den = pop80/sqmi)
min <- round(min(nhood$den), 0)
max <- round(max(nhood$den), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+1
breaks[5] <- breaks[5]-1

plot_den <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = den), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "OrRd", name = "Population\nper Sq. Mi.", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Population Density, 1980",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via U.S. Census Bureau and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# race
nhood <- mutate(nhood, pct = (black80/pop80)*100)
min <- round(min(nhood$pct), 0)
max <- round(max(nhood$pct), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+.1
breaks[5] <- breaks[5]-.1

plot_race <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = pct), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "RdPu", name = "% African American", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Percent Black, 1980",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via U.S. Census Bureau and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# save
cp_plotSave(here("results", "Map_PctBlack", "map_1980_black.png"), plot_race, preset = "lg", dpi = 500)
cp_plotSave(here("results", "Map_PopDensity", "map_1980_pop_density.png"), plot_den, preset = "lg", dpi = 500)
```

### 1990

We’ll repeat the same code for 1990:

``` r
# population density
nhood <- mutate(nhood, den = pop90/sqmi)
min <- round(min(nhood$den), 0)
max <- round(max(nhood$den), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+1
breaks[5] <- breaks[5]-1

plot_den <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = den), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "OrRd", name = "Population\nper Sq. Mi.", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Population Density, 1990",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via U.S. Census Bureau and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# race
nhood <- mutate(nhood, pct = (black90/pop90)*100)
min <- round(min(nhood$pct), 0)
max <- round(max(nhood$pct), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+.2
breaks[5] <- breaks[5]-.1

plot_race <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = pct), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "RdPu", name = "% African American", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Percent Black, 1990",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via U.S. Census Bureau and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# save
cp_plotSave(here("results", "Map_PctBlack", "map_1990_black.png"), plot_race, preset = "lg", dpi = 500)
cp_plotSave(here("results", "Map_PopDensity", "map_1990_pop_density.png"), plot_den, preset = "lg", dpi = 500)
```

### 2000

We’ll repeat the same code for 2000:

``` r
# population density
nhood <- mutate(nhood, den = pop00/sqmi)
min <- round(min(nhood$den), 0)
max <- round(max(nhood$den), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+1
breaks[5] <- breaks[5]-1

plot_den <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = den), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "OrRd", name = "Population\nper Sq. Mi.", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Population Density, 2000",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via U.S. Census Bureau and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# race
nhood <- mutate(nhood, pct = (black00/pop00)*100)
min <- round(min(nhood$pct), 0)
max <- round(max(nhood$pct), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+.4
breaks[5] <- breaks[5]-.1

plot_race <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = pct), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "RdPu", name = "% African American", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Percent Black, 2000",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via U.S. Census Bureau and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# save
cp_plotSave(here("results", "Map_PctBlack", "map_2000_black.png"), plot_race, preset = "lg", dpi = 500)
cp_plotSave(here("results", "Map_PopDensity", "map_2000_pop_density.png"), plot_den, preset = "lg", dpi = 500)
```

### 2010

We’ll repeat the same code for 2010:

``` r
# population density
nhood <- mutate(nhood, den = pop10/sqmi)
min <- round(min(nhood$den), 0)
max <- round(max(nhood$den), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+1
breaks[5] <- breaks[5]-1

plot_den <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = den), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "OrRd", name = "Population\nper Sq. Mi.", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Population Density, 2010",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via U.S. Census Bureau and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# race
nhood <- mutate(nhood, pct = (black10/pop10)*100)
min <- round(min(nhood$pct), 0)
max <- round(max(nhood$pct), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+.5
breaks[5] <- breaks[5]-.1

plot_race <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = pct), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "RdPu", name = "% African American", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Percent Black, 2010",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via U.S. Census Bureau and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# save
cp_plotSave(here("results", "Map_PctBlack", "map_2010_black.png"), plot_race, preset = "lg", dpi = 500)
cp_plotSave(here("results", "Map_PopDensity", "map_2010_pop_density.png"), plot_den, preset = "lg", dpi = 500)
```

### 2017

We’ll repeat the same code for 2017:

``` r
# population density
nhood <- mutate(nhood, den = pop17/sqmi)
min <- round(min(nhood$den), 0)
max <- round(max(nhood$den), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+1
breaks[5] <- breaks[5]-1

plot_den <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = den), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "OrRd", name = "Population\nper Sq. Mi.", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Population Density, 2017",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via U.S. Census Bureau and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# race
nhood <- mutate(nhood, pct = (black17/pop17)*100)
min <- round(min(nhood$pct), 0)
max <- round(max(nhood$pct), 0)
breaks <- c(seq(from = min, to = max, length.out = 5))
breaks[1] <- breaks[1]+.3
breaks[5] <- breaks[5]-.4

plot_race <- ggplot() +
  geom_sf(data = nhood_sf, fill = "#006a14", color = NA) +
  geom_sf(data = nhood, mapping = aes(fill = pct), color = NA) +
  geom_sf(data = nhood_sf, fill = NA, color = "black") +
  scale_fill_distiller(palette = "RdPu", name = "% African American", trans = "reverse",
                       breaks = breaks) +
  labs(
    title = "Percent Black, 2017",
    subtitle = "City of St. Louis Modern Neighborhoods",
    caption = "Map by Christopher Prener, PhD. and Carter Hanford, B.A.\nData via U.S. Census Bureau and the City of St. Louis") +
  cp_sequoiaTheme(base_size = 20, background = "white", map = TRUE)

# save
cp_plotSave(here("results", "Map_PctBlack", "map_2017_black.png"), plot_race, preset = "lg", dpi = 500)
cp_plotSave(here("results", "Map_PopDensity", "map_2017_pop_density.png"), plot_den, preset = "lg", dpi = 500)
```
