# STL_DEMOGRAPHY_NhoodPop

This repository contains code for creating a data set originally requested by Janelle O'Day at the St. Louis Post-Dispatch. The original request was for population estimates similar to those found [here](https://chris-prener.github.io/dataviz/project/stl-pop-change/) but for each year between 2010 and 2017. This repository contains data for the original request as well as estimates derived from each decennial census between 1940 and 2000. 

## Sources

* Underlying decennial census data for 1940-2000 were obtained from [Social Explorer](http://socialexplorer.com)
* Underlying census tract geometry for 1940-2000 were obtained from the [IPUMS](https://www.ipums.org) [National Historical Geographic Information System (NHGIS)](https://www.nhgis.org).
* Underlying decennial census data for 2010 and ACS data 5-year estimates for periods ending in 2011 through 2017 were obtained from the Census Bureau via API (using the `tidycensus` package for `R`)
* Underlying census tract geometry for 2010 were obtained from the Census Bureau via API (using the `tidycensus` package for `R`)
* Neighborhood geometry were obtained from the [City of St. Louis](https://www.stlouis-mo.gov/data/boundaries/ward-neighborhood-boundaries.cfm)

## Methods
The original census tract geometry for 1940-2000 were cleaned prior to inclusion in this repository to remove tracts outside of the City of St. Louis (they were nationwide files). Each year's estimate was produced using `R` and a technique called [areal weighted interpolation](https://slu-opengis.github.io/areal/articles/areal-weighted-interpolation.html). This is typically used for population data (like what we have here) that are overlapping but whose boundaries are incongruent. 

Data for 1940 through 2000 were imported one year at a time, cleaned, and interpolated to the neighborhood boundaries. These neighborhood estimates were then collapsed into a single data frame. Unit tests were used to verify identification variables uniquely identified each historical census tract (since identification numbers changed each decade). Unit tests were also used to verify that each individual counted in a given census year had been redistributed into a neighborhood - the sum of all census tracts for a given year should equal the sum of all neighborhood populations for that same year.

Data for 2010 through 2017 were downloaded and cleaned one at a time, and then combined into a single data frame. That single data frame was then interpolated to the neighborhood boundaries. As before, unit tests were also used to verify that each individual counted in a given census year had been redistributed into a neighborhood.

The two data frames, one for the historical data (1940-2000) and one for the modern data (2010-2017) were then combined and written to the file found at `data/clean/STL_PopByNhood.csv`. All `R` code is found in `docs/buildData.Rmd` along with `.md` and `.nb.html` output files. All original source data can be found in `data/spatial/` and `data/tabular`.

## Notes

### Sources of Error - All Data
The process I use to create the neighborhood estimates, [areal weighted interpolation](https://slu-opengis.github.io/areal/articles/areal-weighted-interpolation.html), introduces some area because it assumes that individuals are evenly spread throughout the source features. Imagine a census tract that is evenly split between a residential area and a commercial area with no residential population. Areal weighted interpolation isn't capable of estimating this level of complexity - it assumes that half the people live in the the commercial area. So, it isn't perfect. It is the simplest approach and the most common for estimating data for overlapping but incongruent spatial features. This approach therefore also introduces noise into the estimates.

Once particular note is that the neighborhood data used for estimates have had six parks removed from them. This reduces the amount of error in the estimation by not allowing anyone to be counted as a resident of the areas covered Carondelet Park, Tower Grove Park, Forest Park, Fairground Park, Penrose Park, O'Fallon Park, Belfontaine/Calvary Cemetery, Missouri Botanical Garden, and Wilmore Park.

### Sources of Error - Estimates Based on the ACS
1. The American Community Survey 5-year estimates are [pooled](https://www.census.gov/programs-surveys/acs/guidance/estimates.html) over a period of 5 years, so they are the most reliable of the 5-year estimates but the least current. Some analysts use the midpoint year (so 2013-2017's 5 year estimate midpoint year would be 2014) as the "actual year" that these data represent for this reason. 
2. The ACS are different than Decennial Census values - the ACS estimates come with a [margin of error](https://walkerke.github.io/tidycensus/articles/margins-of-error.html) that represents the number of individuals (plus or minus) the population value may be off by.

So, bottom line, these data are not census data but rather population estimates, which have been used to produce neighborhood-level estimates. At each level of abstraction, then, there is going to be some error. They're therefore indicative of trends but fundamentally different than then decennial census data.
