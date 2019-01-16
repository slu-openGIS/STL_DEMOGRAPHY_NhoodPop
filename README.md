# PD_nhoodChange

This private repository contains code for creating a data set requested by Janelle at the Post-Dispatch. She asked for population estimates similar to those found [here](https://chris-prener.github.io/dataviz/project/stl-pop-change/) but for each year between 2010 and 2017.

## Notes
There are three possible sources of error with these data:

1. The American Community Survey 5-year estimates are [pooled](https://www.census.gov/programs-surveys/acs/guidance/estimates.html) over a period of 5 years, so they are the most reliable of the 5-year estimates but the least current. Some analysts use the midpoint year (so 2013-2017's 5 year estimate midpoint year would be 2014) as the "actual year" that these data represent for this reason. 
2. The ACS are different than Decennial Census values - the ACS estimates come with a [margin of error](https://walkerke.github.io/tidycensus/articles/margins-of-error.html) that represents the number of individuals (plus or minus) the population value may be off by.
3. The process I use to create the neighborhood estimates is called [areal weighted interpolation](https://slu-opengis.github.io/areal/articles/areal-weighted-interpolation.html) - this introduces some area because it assumes that individuals are evenly spread throughout the source features. Imagine a census tract that straddles Forest Park - have the tract is unpopulated (the half in the park) and the other half is populated. Areal weighted interpolation isn't capable of estimating this level of complexity - it assumes that half the people live in the park. So, it isn't perfect. It is the simplest approach and the most common for estimating data for overlapping but incongruent spatial features. This approach therefore also introduces noise into the estimates.

So, bottom line, these data are not census data but rather population estimates, which have been use to produce neighborhood-level estimates. At each level of abstraction, then, there is going to be some error. They're therefore indicitive of trends but fundamentally different than then 2010 census data, which are only subject to point 3 (because they've been interpolated).