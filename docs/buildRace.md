Build Race Data
================
Christopher Prener, Ph.D.
(September 06, 2019)

## Introduction

This notebook creates neighborhood population estimates for both white
and African American residents.

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
library(stringr)       # string tools

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

    ## here() starts at /Users/prenercg/GitHub/STL_DEMOGRAPHY_NhoodPop

``` r
library(testthat)      # unit testing
```

    ## 
    ## Attaching package: 'testthat'

    ## The following object is masked from 'package:dplyr':
    ## 
    ##     matches

We also use a function for unit testing ID numbers:

``` r
source(here("source", "unique_id.R"))
```

## Create Demographic Data, 1940-2000

These decennial census data were obtained from two sources. The
tract-level shapefiles were obtained from IPUMS’
[NHGIS](https://www.nhgis.org) database. They come for the entire U.S.
(or as much of the U.S. as was tracted at that point - full tract
coverage is relatively recent). They were merged with tract-level data
obtained from [NHGIS](http://socialexplorer.com) that was already clean
and ready to use for each decade.

### 1940

First, we need to load the shapefile
geometry:

``` r
st_read(here("data", "spatial", "STL_DEMOGRAPHICS_tracts40", "STL_DEMOGRAPHICS_tracts40.shp"),
        stringsAsFactors = FALSE) %>%
  st_transform(crs = 26915) -> stl40
```

    ## Reading layer `STL_DEMOGRAPHICS_tracts40' from data source `/Users/prenercg/GitHub/STL_DEMOGRAPHY_NhoodPop/data/spatial/STL_DEMOGRAPHICS_tracts40/STL_DEMOGRAPHICS_tracts40.shp' using driver `ESRI Shapefile'
    ## Simple feature collection with 128 features and 1 field
    ## geometry type:  POLYGON
    ## dimension:      XY
    ## bbox:           xmin: -90.32052 ymin: 38.53185 xmax: -90.16641 ymax: 38.77435
    ## epsg (SRID):    NA
    ## proj4string:    +proj=longlat +ellps=GRS80 +no_defs

Next, we need to load the census data and combine it with the spatial
data. We need to create the `TRACTID` variable out of a larger variable
named `Geo_Name`. A unit test is included to ensure that the `TRACTID`
variable we are creating uniquely identifies observations:

``` r
read_csv(here("data", "tabular", "STL_DEMOGRAPHICS_race40.csv")) %>%
  select(tractID, white, nonwhite) %>%
  mutate(tractID = str_pad(string = tractID, width = 5, side = "left", pad = "0")) -> race40
```

    ## Parsed with column specification:
    ## cols(
    ##   year = col_double(),
    ##   countyID = col_double(),
    ##   tractID = col_character(),
    ##   white = col_double(),
    ##   nonwhite = col_double()
    ## )

``` r
# unit test
race40 %>% unique_id(tractID) -> idUnique
expect_equal(idUnique, TRUE)

# join data
stl40 <- left_join(stl40, race40, by = c("TRACTID" = "tractID"))
```

Finally, we’ll use a technique called [areal weighted
interpolation](https://slu-opengis.github.io/areal/articles/areal-weighted-interpolation.html)
to produce estimates at the neighborhood level. We’ll import the
neighborhood data, re-project it so that it matches the projection used
for the 1940 tract boundaries, subset it so that we have only the needed
columns and only residential neighborhoods (large parks removed), and
then interpolate all of the tract data into neighborhoods.

``` r
# interpolate
st_read(here("data", "spatial", "nhood", "BND_Nhd88_cw.shp"), stringsAsFactors = FALSE) %>%
  st_transform(crs = 26915) %>%
  select(NHD_NAME, NHD_NUM) %>%
  filter(NHD_NUM <= 79) %>%
  aw_interpolate(tid = NHD_NUM, source = stl40, sid = TRACTID, 
                 weight = "sum", output = "tibble", 
                 extensive = c("white", "nonwhite")) -> nhood40
```

    ## Reading layer `BND_Nhd88_cw' from data source `/Users/prenercg/GitHub/STL_DEMOGRAPHY_NhoodPop/data/spatial/nhood/BND_Nhd88_cw.shp' using driver `ESRI Shapefile'
    ## Simple feature collection with 88 features and 6 fields
    ## geometry type:  MULTIPOLYGON
    ## dimension:      XY
    ## bbox:           xmin: 871512.3 ymin: 982994.4 xmax: 912850.5 ymax: 1070957
    ## epsg (SRID):    NA
    ## proj4string:    +proj=tmerc +lat_0=35.83333333333334 +lon_0=-90.5 +k=0.9999333333333333 +x_0=250000 +y_0=0 +datum=NAD83 +units=us-ft +no_defs

``` r
# unit test
expect_equal(aw_verify(source = stl40, sourceValue = white, result = nhood40, resultValue = white), TRUE)
expect_equal(aw_verify(source = stl40, sourceValue = nonwhite, result = nhood40, resultValue = nonwhite), TRUE)

# rename race variables
nhood40 <- rename(nhood40, white40 = white, nonwhite40 = nonwhite)

# clean-up enviornment
rm(race40, stl40)
```

For tracts that straddle one of the large parks, their entire population
is allocated into the appropriate adjacent neighborhood. We confirm that
the entire city’s population using a unit test with the `aw_verify()`
function. As long as `aw_verify()` returns `TRUE`, we know that each
resident has been allocated. We wrap this in a unit test so that the
code errors out if this assumption is not met.

### 1950

For the remainder of the decennial census data, I’m going to use the
same workflow but condense the code.

``` r
# read in 1950 era tract boundaries, re-project
st_read(here("data", "spatial", "STL_DEMOGRAPHICS_tracts50", "STL_DEMOGRAPHICS_tracts50.shp"),
        stringsAsFactors = FALSE) %>%
  st_transform(crs = 26915) -> stl50
```

    ## Reading layer `STL_DEMOGRAPHICS_tracts50' from data source `/Users/prenercg/GitHub/STL_DEMOGRAPHY_NhoodPop/data/spatial/STL_DEMOGRAPHICS_tracts50/STL_DEMOGRAPHICS_tracts50.shp' using driver `ESRI Shapefile'
    ## Simple feature collection with 128 features and 1 field
    ## geometry type:  POLYGON
    ## dimension:      XY
    ## bbox:           xmin: -90.32051 ymin: 38.53185 xmax: -90.16641 ymax: 38.77435
    ## epsg (SRID):    NA
    ## proj4string:    +proj=longlat +ellps=GRS80 +no_defs

``` r
# read in 1950 census counts, clean
read_csv(here("data", "tabular", "STL_DEMOGRAPHICS_race50.csv")) %>%
  select(tractID, white, black) %>%
  mutate(tractID = str_pad(string = tractID, width = 5, side = "left", pad = "0")) -> race50
```

    ## Parsed with column specification:
    ## cols(
    ##   year = col_double(),
    ##   countyID = col_double(),
    ##   tractID = col_character(),
    ##   white = col_double(),
    ##   black = col_double(),
    ##   other = col_double()
    ## )

``` r
# unit test
race50 %>% unique_id(tractID) -> idUnique
expect_equal(idUnique, TRUE)

# join data
stl50 <- left_join(stl50, race50, by = c("TRACTID" = "tractID"))

# interpolate to neighborhoods
st_read(here("data", "spatial", "nhood", "BND_Nhd88_cw.shp"), stringsAsFactors = FALSE) %>%
  st_transform(crs = 26915) %>%
  select(NHD_NUM) %>%
  filter(NHD_NUM <= 79) %>%
  aw_interpolate(tid = NHD_NUM, source = stl50, sid = TRACTID, 
                 weight = "sum", output = "tibble", 
                 extensive = c("white", "black")) -> nhood50
```

    ## Reading layer `BND_Nhd88_cw' from data source `/Users/prenercg/GitHub/STL_DEMOGRAPHY_NhoodPop/data/spatial/nhood/BND_Nhd88_cw.shp' using driver `ESRI Shapefile'
    ## Simple feature collection with 88 features and 6 fields
    ## geometry type:  MULTIPOLYGON
    ## dimension:      XY
    ## bbox:           xmin: 871512.3 ymin: 982994.4 xmax: 912850.5 ymax: 1070957
    ## epsg (SRID):    NA
    ## proj4string:    +proj=tmerc +lat_0=35.83333333333334 +lon_0=-90.5 +k=0.9999333333333333 +x_0=250000 +y_0=0 +datum=NAD83 +units=us-ft +no_defs

``` r
# unit test
expect_equal(aw_verify(source = stl50, sourceValue = white, result = nhood50, resultValue = white), TRUE)
expect_equal(aw_verify(source = stl50, sourceValue = black, result = nhood50, resultValue = black), TRUE)

# rename race variables
nhood50 <- rename(nhood50, white50 = white, black50 = black)

# clean-up enviornment
rm(race50, stl50)
```

### 1960

The 1960 process is very similar to the 1950 one:

``` r
# read in 1960 era tract boundaries, re-project
st_read(here("data", "spatial", "STL_DEMOGRAPHICS_tracts60", "STL_DEMOGRAPHICS_tracts60.shp"),
        stringsAsFactors = FALSE) %>%
  st_transform(crs = 26915) -> stl60
```

    ## Reading layer `STL_DEMOGRAPHICS_tracts60' from data source `/Users/prenercg/GitHub/STL_DEMOGRAPHY_NhoodPop/data/spatial/STL_DEMOGRAPHICS_tracts60/STL_DEMOGRAPHICS_tracts60.shp' using driver `ESRI Shapefile'
    ## Simple feature collection with 128 features and 1 field
    ## geometry type:  POLYGON
    ## dimension:      XY
    ## bbox:           xmin: -90.32051 ymin: 38.53185 xmax: -90.16641 ymax: 38.77435
    ## epsg (SRID):    NA
    ## proj4string:    +proj=longlat +ellps=GRS80 +no_defs

``` r
# read in 1960 census counts, clean
read_csv(here("data", "tabular", "STL_DEMOGRAPHICS_race60.csv")) %>%
  select(tractID, white, black) %>%
  mutate(tractID = str_pad(string = tractID, width = 5, side = "left", pad = "0")) -> race60
```

    ## Parsed with column specification:
    ## cols(
    ##   year = col_double(),
    ##   countyID = col_double(),
    ##   tractID = col_character(),
    ##   white = col_double(),
    ##   black = col_double(),
    ##   other = col_double()
    ## )

``` r
# unit test
race60 %>% unique_id(tractID) -> idUnique
expect_equal(idUnique, TRUE)

# join data
stl60 <- left_join(stl60, race60, by = c("TRACTID" = "tractID"))

# interpolate to neighborhoods
st_read(here("data", "spatial", "nhood", "BND_Nhd88_cw.shp"), stringsAsFactors = FALSE) %>%
  st_transform(crs = 26915) %>%
  select(NHD_NUM) %>%
  filter(NHD_NUM <= 79) %>%
  aw_interpolate(tid = NHD_NUM, source = stl60, sid = TRACTID, 
                 weight = "sum", output = "tibble", 
                 extensive = c("white", "black")) -> nhood60
```

    ## Reading layer `BND_Nhd88_cw' from data source `/Users/prenercg/GitHub/STL_DEMOGRAPHY_NhoodPop/data/spatial/nhood/BND_Nhd88_cw.shp' using driver `ESRI Shapefile'
    ## Simple feature collection with 88 features and 6 fields
    ## geometry type:  MULTIPOLYGON
    ## dimension:      XY
    ## bbox:           xmin: 871512.3 ymin: 982994.4 xmax: 912850.5 ymax: 1070957
    ## epsg (SRID):    NA
    ## proj4string:    +proj=tmerc +lat_0=35.83333333333334 +lon_0=-90.5 +k=0.9999333333333333 +x_0=250000 +y_0=0 +datum=NAD83 +units=us-ft +no_defs

``` r
# unit test
expect_equal(aw_verify(source = stl60, sourceValue = white, result = nhood60, resultValue = white), TRUE)
expect_equal(aw_verify(source = stl60, sourceValue = black, result = nhood60, resultValue = black), TRUE)

# rename race variables
nhood60 <- rename(nhood60, white60 = white, black60 = black)

# clean-up enviornment
rm(race60, stl60)
```

### 1970

Beginning in 1970, the tract ID numbers changed, and so our process for
joining these data does as well.

``` r
# read in 1970 era tract boundaries, re-project
st_read(here("data", "spatial", "STL_DEMOGRAPHICS_tracts70", "STL_DEMOGRAPHICS_tracts70.shp"),
        stringsAsFactors = FALSE) %>%
  st_transform(crs = 26915) -> stl70
```

    ## Reading layer `STL_DEMOGRAPHICS_tracts70' from data source `/Users/prenercg/GitHub/STL_DEMOGRAPHY_NhoodPop/data/spatial/STL_DEMOGRAPHICS_tracts70/STL_DEMOGRAPHICS_tracts70.shp' using driver `ESRI Shapefile'
    ## Simple feature collection with 126 features and 1 field
    ## geometry type:  POLYGON
    ## dimension:      XY
    ## bbox:           xmin: -90.32051 ymin: 38.53185 xmax: -90.16641 ymax: 38.77435
    ## epsg (SRID):    NA
    ## proj4string:    +proj=longlat +ellps=GRS80 +no_defs

``` r
# read in 1970 census counts, clean
read_csv(here("data", "tabular", "STL_DEMOGRAPHICS_race70.csv")) %>%
  select(tractID, white, black) %>%
  mutate(tractID = as.integer(str_pad(string = tractID, width = 6, side = "right", pad = "0"))) -> race70
```

    ## Parsed with column specification:
    ## cols(
    ##   year = col_double(),
    ##   countyID = col_double(),
    ##   tractID = col_double(),
    ##   white = col_double(),
    ##   black = col_double(),
    ##   other = col_double()
    ## )

``` r
# unit test
race70 %>% unique_id(tractID) -> idUnique
expect_equal(idUnique, TRUE)

# join data
stl70 <- left_join(stl70, race70, by = c("TRACTID" = "tractID"))

# interpolate to neighborhoods
st_read(here("data", "spatial", "nhood", "BND_Nhd88_cw.shp"), stringsAsFactors = FALSE) %>%
  st_transform(crs = 26915) %>%
  select(NHD_NUM) %>%
  filter(NHD_NUM <= 79) %>%
  aw_interpolate(tid = NHD_NUM, source = stl70, sid = TRACTID, 
                 weight = "sum", output = "tibble", 
                 extensive = c("white", "black")) -> nhood70
```

    ## Reading layer `BND_Nhd88_cw' from data source `/Users/prenercg/GitHub/STL_DEMOGRAPHY_NhoodPop/data/spatial/nhood/BND_Nhd88_cw.shp' using driver `ESRI Shapefile'
    ## Simple feature collection with 88 features and 6 fields
    ## geometry type:  MULTIPOLYGON
    ## dimension:      XY
    ## bbox:           xmin: 871512.3 ymin: 982994.4 xmax: 912850.5 ymax: 1070957
    ## epsg (SRID):    NA
    ## proj4string:    +proj=tmerc +lat_0=35.83333333333334 +lon_0=-90.5 +k=0.9999333333333333 +x_0=250000 +y_0=0 +datum=NAD83 +units=us-ft +no_defs

``` r
# unit test
expect_equal(aw_verify(source = stl70, sourceValue = white, result = nhood70, resultValue = white), TRUE)
expect_equal(aw_verify(source = stl70, sourceValue = black, result = nhood70, resultValue = black), TRUE)

# rename race variables
nhood70 <- rename(nhood70, white70 = white, black70 = black)

# clean-up enviornment
rm(race70, stl70)
```

### 1980

The 1980 workflow mirrors the 1970 one:

``` r
# read in 1980 era tract boundaries, re-project
st_read(here("data", "spatial", "STL_DEMOGRAPHICS_tracts80", "STL_DEMOGRAPHICS_tracts80.shp"),
        stringsAsFactors = FALSE) %>%
  st_transform(crs = 26915) -> stl80
```

    ## Reading layer `STL_DEMOGRAPHICS_tracts80' from data source `/Users/prenercg/GitHub/STL_DEMOGRAPHY_NhoodPop/data/spatial/STL_DEMOGRAPHICS_tracts80/STL_DEMOGRAPHICS_tracts80.shp' using driver `ESRI Shapefile'
    ## Simple feature collection with 113 features and 1 field
    ## geometry type:  POLYGON
    ## dimension:      XY
    ## bbox:           xmin: -90.32051 ymin: 38.53185 xmax: -90.16641 ymax: 38.77435
    ## epsg (SRID):    NA
    ## proj4string:    +proj=longlat +ellps=GRS80 +no_defs

``` r
# read in 1980 census counts, clean
read_csv(here("data", "tabular", "STL_DEMOGRAPHICS_race80.csv")) %>%
  select(tractID, white, black) %>%
  mutate(tractID = as.integer(str_pad(string = tractID, width = 6, side = "right", pad = "0"))) -> race80
```

    ## Parsed with column specification:
    ## cols(
    ##   year = col_double(),
    ##   countyID = col_double(),
    ##   tractID = col_double(),
    ##   white = col_double(),
    ##   black = col_double(),
    ##   other = col_double()
    ## )

``` r
# unit test
race80 %>% unique_id(tractID) -> idUnique
expect_equal(idUnique, TRUE)

# join data
stl80 <- left_join(stl80, race80, by = c("TRACTID" = "tractID"))

# interpolate to neighborhoods
st_read(here("data", "spatial", "nhood", "BND_Nhd88_cw.shp"), stringsAsFactors = FALSE) %>%
  st_transform(crs = 26915) %>%
  select(NHD_NUM) %>%
  filter(NHD_NUM <= 79) %>%
  aw_interpolate(tid = NHD_NUM, source = stl80, sid = TRACTID, 
                 weight = "sum", output = "tibble", 
                 extensive = c("white", "black")) -> nhood80
```

    ## Reading layer `BND_Nhd88_cw' from data source `/Users/prenercg/GitHub/STL_DEMOGRAPHY_NhoodPop/data/spatial/nhood/BND_Nhd88_cw.shp' using driver `ESRI Shapefile'
    ## Simple feature collection with 88 features and 6 fields
    ## geometry type:  MULTIPOLYGON
    ## dimension:      XY
    ## bbox:           xmin: 871512.3 ymin: 982994.4 xmax: 912850.5 ymax: 1070957
    ## epsg (SRID):    NA
    ## proj4string:    +proj=tmerc +lat_0=35.83333333333334 +lon_0=-90.5 +k=0.9999333333333333 +x_0=250000 +y_0=0 +datum=NAD83 +units=us-ft +no_defs

``` r
# unit test
expect_equal(aw_verify(source = stl80, sourceValue = white, result = nhood80, resultValue = white), TRUE)
expect_equal(aw_verify(source = stl80, sourceValue = black, result = nhood80, resultValue = black), TRUE)

# rename race variables
nhood80 <- rename(nhood80, white80 = white, black80 = black)

# clean-up enviornment
rm(race80, stl80)
```

### Combine 1940s-1980s Data

Next, we’ll join all of the neighborhood estimates we’ve created so far
together into a single object:

``` r
left_join(nhood40, nhood50, by = "NHD_NUM") %>%
  left_join(., nhood60, by = "NHD_NUM") %>%
  left_join(., nhood70, by = "NHD_NUM") %>%
  left_join(., nhood80, by = "NHD_NUM") -> nhoodPop_40_80

# clean up enviornment
rm(nhood40, nhood50, nhood60, nhood70, nhood80, idUnique, unique_id)
```
