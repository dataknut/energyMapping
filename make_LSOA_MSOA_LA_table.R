# make a table of LSOA <-> MSOA <-> LA codes and names for ease of use

# Libraries ----
library(data.table)

# Data paths ----
user <- Sys.info()[[7]] # who are we logged in as?
if(user == "ben"){
  dataFolder <- path.expand("~/University of Southampton/HCC Energy Landscape Mapping project - Documents/General/data/")
}

message("User: ", user)
message("dataFolder: ", dataFolder)

# Functions ----

selectSoton <- function(dt){
  # function we can re-use
  # assumes a data.table
  # assumes LA name = la_name (may need to make new var first)
  # returns just the rows that have Local Authority == Southampton
  select_dt <- dt[la_name %like% "Southampton"]
  return(select_dt)
}

selectSolent <- function(dt){
  # function we can re-use
  # assumes a data.table
  # assumes LA name = la_name (may need to make new var first)
  # returns just the rows that have Local Authority in Solent area
  select_dt <- dt[la_name == "Southampton" | 
                    la_name == "Portsmouth" |
                    la_name == "Winchester" |
                    la_name == "Eastleigh" |
                    la_name == "Isle of Wight" |
                    la_name == "Fareham" |
                    la_name == "Gosport" |
                    la_name == "Test Valley" |
                    la_name == "East Hampshire" |
                    la_name == "Havant" |
                    la_name == "New Forest" |
                    la_name == "Hart" |
                    la_name == "Basingstoke and Deane"]
  return(select_dt)
}

# Code ----
# start from the 2019 domestic elec data
inFile <-paste0(dataFolder, "energy/electricity/LSOA Dom elec csv/LSOA_ELEC_2019.csv")
elec_dt <- data.table::fread(inFile)
elec_dt[, LSOA11CD := `Lower Layer Super Output Area (LSOA) Code`]
elec_dt[, LSOA11NM := `Lower Layer Super Output Area (LSOA) Name`] 

elec_dt[, MSOA11CD := `Middle Layer Super Output Area (MSOA) Code`]
elec_dt[, MSOA11NM := `Middle Layer Super Output Area (MSOA) Name`] 

elec_dt[, LA11CD := `Local Authority Code`]
elec_dt[, LA11NM := `Local Authority Name`] 
setkey(elec_dt, LSOA11CD)

# add in the best-fit wards
# https://geoportal.statistics.gov.uk/datasets/lower-layer-super-output-areas-december-2011-names-and-codes-in-england-and-wales/explore
inFile <-paste0(dataFolder, "lookups/Lower_Layer_Super_Output_Area_(2011)_to_Ward_(2020)_to_LAD_(2020)_Lookup_in_England_and_Wales_V2.csv")
lsoa_ward_dt <- data.table::fread(inFile)
setkey(lsoa_ward_dt, LSOA11CD)

# add in the urban/rural
# source
inFile <-paste0(dataFolder, "urbanRural/Rural_Urban_Classification_(2011)_of_Lower_Layer_Super_Output_Areas_in_England_and_Wales.csv")
lsoa_rurc_dt <- data.table::fread(inFile)
lsoa_rurc_dt$FID <- NULL
setkey(lsoa_rurc_dt, LSOA11CD)

# add in the OAC codes
# https://www.ons.gov.uk/methodology/geography/geographicalproducts/areaclassifications/2011areaclassifications/datasets
inFile <-paste0(dataFolder, "oac/lsoa-oac-data.xls")
library(readxl)
lsoa_oac_dt <- data.table::as.data.table(readxl::read_xls(inFile, sheet = "Clusters by SOA", skip = 11))
lsoa_oac_dt[, LSOA11CD := `SOA Code`]
setkey(lsoa_oac_dt, LSOA11CD)

# merge the tables keeping just the columns we want
lsoa_lookup <- elec_dt[, .(LSOA11CD, LSOA11NM, MSOA11CD, MSOA11NM, LA11CD, LA11NM)][lsoa_ward_dt[, .(LSOA11CD,WD20CD, WD20NM, LAD20CD, LAD20NM)]] # keep LA 2020 names for checking

lsoa_lookup <- lsoa_lookup[lsoa_rurc_dt][lsoa_oac_dt[`Region/Country` != "Northern Ireland" |
                                                       `Region/Country` != "Scotland" ]] # don't exist in the other data

nrow(lsoa_lookup)


data.table::fwrite(lsoa_lookup, file = paste0(dataFolder, "lookups/lsoa_lookup.csv"))

lsoa_lookup[, la_name := LA11NM]
lsoa_lookup_solent <- selectSolent(lsoa_lookup)
data.table::fwrite(lsoa_lookup_solent, file = paste0(dataFolder, "lookups/lsoa_lookup_solent.csv"))

uniqueN(lsoa_lookup$LA11NM) # this should equal the number of rows of this table (no mis-matches or duplicates or NAs)
t <- lsoa_lookup[, .(n = .N), keyby=.(LA11NM, LAD20NM)]
nrow(t)
t

table(lsoa_lookup$RUC11,lsoa_lookup$RUC11CD, useNA = "always")
table(lsoa_lookup$RUC11,lsoa_lookup$`Supergroup Name`, useNA = "always")

head(lsoa_lookup[is.na(RUC11CD)]) # NA in Northern Ireland & Scotland - these countriues only included via OAC...
