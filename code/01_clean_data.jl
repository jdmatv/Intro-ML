using DataFrames
using CSV

## Task 1 - NRI data cleaning
# ensure that 'STCOFIPS' is identified as a string and import NRI CSV data
column_types = Dict(:STCOFIPS => String)
nri_dat = CSV.read("data/raw/NRI_Table_Counties.csv", types=column_types, DataFrame)

# string endings of cols to include and subsetting dat
str_ends = ["_AFREQ", "_RISKR"]
include_cols = ["STCOFIPS"; [i for i in names(nri_dat) if any(endswith(i, str) for str in str_ends)]]
nri_dat_subset = nri_dat[:, include_cols]

# create column AVLN_MISS that = 1 when AVLN_AFREQ missing
transform!(nri_dat_subset, :AVLN_AFREQ => ByRow(ismissing) => :AVLN_MISS)

# list of variables for which to impute missing values
imp_vars = [col for col in names(nri_dat_subset) if endswith(col, "_AFREQ")]
risk_vars = [col for col in names(nri_dat_subset) if endswith(col, "_RISKR")]
new_vars = [i * "_IMP" for i in imp_vars]

# assuming that NA means the freq is 0, impute missing values
impute_missing(x, y) = ifelse.(y .== "Not Applicable" .&& ismissing.(x), 0, x) 

for (iv, rv, nv) in zip(imp_vars, risk_vars, new_vars)
    transform!(nri_dat_subset, [Symbol(iv), Symbol(rv)] => impute_missing => Symbol(nv))
end

## Task 2 - SVI data cleaning
# ensure that 'FIPS' is identified as a string and import data
column_types = Dict(:FIPS => String)
svi_dat = CSV.read("data/raw/SVI_2022_US_county.csv", types=column_types, DataFrame)

# subset data to include given columns
given_columns_str = "ST, STATE, ST_ABBR, STCNTY, COUNTY, FIPS, LOCATION, AREA_SQMI, E_TOTPOP, EP_POV150, EP_UNEMP, EP_HBURD, EP_NOHSDP, EP_UNINSUR, EP_AGE65, EP_AGE17, EP_DISABL, EP_SNGPNT, EP_LIMENG, EP_MINRTY, EP_MUNIT, EP_MOBILE, EP_CROWD, EP_NOVEH, EP_GROUPQ, EP_NOINT, EP_AFAM, EP_HISP, EP_ASIAN, EP_AIAN, EP_NHPI, EP_TWOMORE, EP_OTHERRACE"
given_columns = strip.(split(given_columns_str, ","))
svi_dat_subset = svi_dat[:, given_columns]

## Task 3 - Data merging
# merging both datasets and saving output
merged_nri_svi = outerjoin(nri_dat_subset, svi_dat_subset, on = :STCOFIPS => :FIPS)
CSV.write("data/processed/merged_nri_svi.csv", merged_nri_svi)