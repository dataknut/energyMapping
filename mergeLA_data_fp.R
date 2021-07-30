# useful R libraries
library(readr)
library(dplyr)

dataFolder<-"/Users/megha/Desktop/1. Uni/Masters/Project/Mapping Code/data/" # default for Meghan
user <- Sys.info()[[7]] # who are we logged in as?
if(user == "ben"){
  dataFolder <- path.expand("~/University of Southampton/HCC Energy Landscape Mapping project - Documents/General/data/")
}

# this will not print anything out when knitted due to the include=FALSE setting in the chunk header
message("User: ", user)
message("dataFolder: ", dataFolder)

fp_LA_2019_df <- readr::read_csv(paste0(dataFolder, "/Fuel Poverty/2019 LA_Fuel_Poverty.csv"))

fp_LA_2012_df <- readr::read_csv(paste0(dataFolder, "/Fuel Poverty/2012 LA_Fuel_Poverty.csv"))

merged_df <- merge(fp_LA_2012_df, fp_LA_2019_df, by = "Area Code", all = TRUE)

names(merged_df)

merged_df$pc_diff <-  as.numeric(merged_df$`Proportion of households fuel poor (%)`) - merged_df$`Proportion of households fuel poor (%) 2012`

summary(merged_df)

hist(merged_df$pc_diff)

# GIS libraries
library(raster)
library(sf)
library(spData)
library(spDataLarge)

la_shpFile <- paste0(dataFolder, "/boundaries/LA/la_solent.shp")
la_sf_data <- sf::st_read(la_shpFile)
head(la_sf_data)

mapDF <- merge(la_sf_data, merged_df)

nrow(la_sf_data)

p <- ggplot2::ggplot(mapDF) +
  geom_sf(aes(fill = pc_diff)) +
  scale_fill_gradient(low="green",high="red")
