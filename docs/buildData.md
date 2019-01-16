Build Population Estimate Data
================
Christopher Prener, Ph.D.
(January 15, 2019)

## Introduction

This notebook creates the requested population estimates.

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

# spatial packages
library(areal)         # interpolation
library(sf)            # working with spatial data
```

    ## Linking to GEOS 3.6.1, GDAL 2.1.3, PROJ 4.9.3

``` r
library(tidycensus)    # census api access
library(tigris)        # tiger/line api access
```

    ## To enable 
    ## caching of data, set `options(tigris_use_cache = TRUE)` in your R script or .Rprofile.

    ## 
    ## Attaching package: 'tigris'

    ## The following object is masked from 'package:graphics':
    ## 
    ##     plot

``` r
# other packages
library(here)          # file path management
```

    ## here() starts at /Users/chris/GitHub/Personal/PD_nhoodChange

## Download Demographic Data

All data are downloaded from the Census Bureau’s API via `tidycensus`.

### 2010

These data are from the decennial
census.

``` r
get_decennial(geography = "tract", variables = "P001001", state = 29, county = 510, geometry = TRUE) %>% 
  select(GEOID, NAME, value) %>%
  rename(pop10 = value) -> stl10
```

    ## Getting data from the 2010 decennial Census

    ## Downloading feature geometry from the Census website.  To cache shapefiles for use in future sessions, set `options(tigris_use_cache = TRUE)`.

### 2011

These data are from the 2007-2011 5-year American Community Survey
estimates.

``` r
get_acs(geography = "tract", year = 2011, variables = "B01003_001", state = 29, county = 510) %>%
  select(GEOID, estimate, moe) %>%
  rename(pop11 = estimate,
         pop11_m = moe) -> stl11
```

    ## Getting data from the 2007-2011 5-year ACS

### 2012

These data are from the 2008-2012 5-year American Community Survey
estimates.

``` r
get_acs(geography = "tract", year = 2012, variables = "B01003_001", state = 29, county = 510) %>%
  select(GEOID, estimate, moe) %>%
  rename(pop12 = estimate,
         pop12_m = moe) -> stl12
```

    ## Getting data from the 2008-2012 5-year ACS

### 2013

These data are from the 2009-2013 5-year American Community Survey
estimates.

``` r
get_acs(geography = "tract", year = 2013, variables = "B01003_001", state = 29, county = 510) %>%
  select(GEOID, estimate, moe) %>%
  rename(pop13 = estimate,
         pop13_m = moe) -> stl13
```

    ## Getting data from the 2009-2013 5-year ACS

### 2014

These data are from the 2010-2014 5-year American Community Survey
estimates.

``` r
get_acs(geography = "tract", year = 2014, variables = "B01003_001", state = 29, county = 510) %>%
  select(GEOID, estimate, moe) %>%
  rename(pop14 = estimate,
         pop14_m = moe) -> stl14
```

    ## Getting data from the 2010-2014 5-year ACS

### 2015

These data are from the 2011-2015 5-year American Community Survey
estimates.

``` r
get_acs(geography = "tract", year = 2015, variables = "B01003_001", state = 29, county = 510) %>%
  select(GEOID, estimate, moe) %>%
  rename(pop15 = estimate,
         pop15_m = moe) -> stl15
```

    ## Getting data from the 2011-2015 5-year ACS

### 2016

These data are from the 2012-2016 5-year American Community Survey
estimates.

``` r
get_acs(geography = "tract", year = 2016, variables = "B01003_001", state = 29, county = 510) %>%
  select(GEOID, estimate, moe) %>%
  rename(pop16 = estimate,
         pop16_m = moe) -> stl16
```

    ## Getting data from the 2012-2016 5-year ACS

### 2017

These data are from the 2013-2017 5-year American Community Survey
estimates.

``` r
get_acs(geography = "tract", year = 2017, variables = "B01003_001", state = 29, county = 510) %>%
  select(GEOID, estimate, moe) %>%
  rename(pop17 = estimate,
         pop17_m = moe) -> stl17
```

    ## Getting data from the 2013-2017 5-year ACS

## Combine Data

We have these data in a number of different tables, so the next step is
to join them together by `GEOID`.

``` r
left_join(stl10, stl11, by = "GEOID") %>%
  left_join(., stl12, by = "GEOID") %>%
  left_join(., stl13, by = "GEOID") %>%
  left_join(., stl14, by = "GEOID") %>%
  left_join(., stl15, by = "GEOID") %>%
  left_join(., stl16, by = "GEOID") %>%
  left_join(., stl17, by = "GEOID") %>%
  st_transform(crs = 26915) -> tractPop
```

We’ll write these data to a `.csv` file for future reference:

``` r
# remove geometric data
tractPop_tbl <- tractPop
st_geometry(tractPop_tbl) <- NULL

# write output
write_csv(tractPop_tbl, here("data", "STL_PopByTract.csv"))
```

## Interpolate Neighborhood Data

Next, we’ll use a technique called [areal weighted
interpolation](https://slu-opengis.github.io/areal/articles/areal-weighted-interpolation.html)
to produce estimates at the neighborhood level. As before, we’ll write
the data to a `.csv` file for future analysis.

``` r
# read neighborhood data, re-project, and interpolate
st_read(here("data", "nhood", "BND_Nhd88_cw.shp"), stringsAsFactors = FALSE) %>%
  st_transform(crs = 26915) %>%
  select(NHD_NUM, NHD_NAME) %>%
  aw_interpolate(tid = NHD_NUM, source = tractPop, sid = GEOID, 
                 weight = "sum", output = "sf", 
                 extensive = c("pop10", "pop11", "pop11_m", 
                               "pop12", "pop12_m", "pop13", "pop13_m", 
                               "pop14", "pop14_m", "pop15", "pop15_m", 
                               "pop16", "pop16_m", "pop17", "pop17_m")
                 ) -> nhoodPop
```

    ## Reading layer `BND_Nhd88_cw' from data source `/Users/chris/GitHub/Personal/PD_nhoodChange/data/nhood/BND_Nhd88_cw.shp' using driver `ESRI Shapefile'
    ## Simple feature collection with 88 features and 6 fields
    ## geometry type:  MULTIPOLYGON
    ## dimension:      XY
    ## bbox:           xmin: 871512.3 ymin: 982994.4 xmax: 912850.5 ymax: 1070957
    ## epsg (SRID):    NA
    ## proj4string:    +proj=tmerc +lat_0=35.83333333333334 +lon_0=-90.5 +k=0.9999333333333333 +x_0=250000 +y_0=0 +datum=NAD83 +units=us-ft +no_defs

``` r
# remove geometric data
st_geometry(nhoodPop) <- NULL

# write output
write_csv(nhoodPop, here("data", "STL_PopByNhood.csv"))
```
