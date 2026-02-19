# The “Educational attainment – Geodata” product provides detailed information on the highest level of education 
# completed by the permanent resident population aged 25 to 64 across Switzerland. This data is based on several 
# statistical surveys conducted by the federal administration and is supplemented by a two-stage imputation model 
# that estimates missing data. The level of education is reported according to a three-stage nomenclature: compulsory 
# schooling, secondary level II, and tertiary level. Data is available for the reference years 1990 and 2000, as well 
# as for each year from 2017 onwards. It is provided for all of Switzerland at three spatial resolutions: hectares 
# (100 x 100 m grid), first-level spatial statistical units (USPAT1 regions), and municipalities.

# Acknowledgement: For this code I heavily relied on previous code developed by Ludovica Alesci (thank you Ludo!)

# Author: Igor Francetic
# This version: October 2025

######################################################################################################################################################
######################################################################################################################################################

rm(list = ls())
setwd ("T:/AMBIZIONE/WP2/Igor")

# Reassign paths
myPaths <- .libPaths()
myPaths <- c(myPaths, "E:/Users/igor.francetic/win-library/4.5")
.libPaths(myPaths)  # add new path
myPaths <- .libPaths()   # get the paths
myPaths <- c(myPaths[3],  myPaths[2] , myPaths[1])  # switch them
.libPaths(myPaths)  # reassign them

# EPSG:2056
library(tmap)
library(sf)
library(dplyr)
library(ggplot2)
library(viridis)
library(patchwork)

for (x in 2017:2022) {

url <- paste0("https://data.geo.admin.ch/ch.bfs.bildungsstand/bildungsstand_", x, "/bildungsstand_", x, "_2056" , ".gpkg")

# file temporaneo in cui salvare dati download
destfile <- tempfile(fileext = ".gpkg")
download.file(url, destfile, mode = "wb")

municipality <- st_read(destfile, layer = "Gemeinden")
medstat <- st_read("https://www.versorgungsatlas.ch/geo/medstat.geojson",
                   stringsAsFactors = FALSE,
                   as_tibble = TRUE) #default WGS 84

# 1. Cleaning data ####################################################################################################################################

# a. Municipality data  --------------------------------------------------------------------------------------------------------------------------
municipality <- municipality %>% select(-ERHJAHR, -PUBJAHR)

municipality <- municipality %>% 
  rename(
    population = BBTOT25_64, 
    compulsory_count = COMPULSORY_C,
    secondary_count    = SECONDARYII_C,
    tertiary_count       = TERTIARY_C,
    compulsory_share = COMPULSORY,
    secondary_share    = SECONDARYII,
    tertiary_share       = TERTIARY,
    municipality = GDENAME,
    imputation = IMPUTATION,
    municipality_n = GDENR,
    municipality_histid = GDEHISTID
  )

# 2. Aggregate geographiesand merge education data #####################################################################################################

# CRS uguali
#st_crs(municipalities_geojson) #4326
#st_crs(municipality) #2056
# forcing the coordinate system (the file uses the Swiss one, while I need wgs84)
# 2056 = switzerland
# 4326 = global

st_crs(medstat) <- 2056
municipalities_geojson <- st_transform(municipality, 4326)
medstats_geojson <- st_transform(medstat, crs = 4326)

# add country for each medstat
medstats_geojson$country <- "Switzerland"

# divide the canton from the column region_id (medstat) con primi due caratteri
medstats_geojson$canton <- substr(medstats_geojson$region_id, 1, 2)
st_crs(municipalities_geojson) #4326
st_crs(medstats_geojson) #4326

# unisco comune + medstat + education tramite intersezione di poligoni
comm_with_medstat <- st_join(
  municipalities_geojson[, c("compulsory_share","secondary_share","tertiary_share")],
  medstats_geojson[, "region_id"],
  join = st_intersects)

# media delle % education per MedStat in base a municipality
medstat_education <- comm_with_medstat %>%
  st_set_geometry(NULL) %>%
  group_by(region_id) %>%
  summarise(
    compulsory_share = mean(compulsory_share, na.rm = TRUE),
    secondary_share   = mean(secondary_share, na.rm = TRUE),
    tertiary_share    = mean(tertiary_share, na.rm = TRUE))

# unisco geometrie
medstats_geojson_ed <- medstats_geojson %>%
  left_join(medstat_education, by = "region_id")

temp<-as.data.frame(medstats_geojson_ed)
vars <- names(temp) %in% c("region_id","compulsory_share","secondary_share", "tertiary_share")
medstateducation <- as.data.frame(temp[vars])



# 3. Save the file using the constructed name 
file_name <- paste0("dataout/medstateducation_", x, ".csv")
write.csv(medstateducation, 
          file = file_name, 
          row.names = FALSE)  ## Saving csv file for later use in Stata

rm(comm_with_medstat, municipality, medstat_education, temp)

# 3. Plot maps ##########################################################################################################
# plot compulsory
p4 <- ggplot(medstats_geojson_ed) +
  geom_sf(aes(fill = compulsory_share), color = "white", size = 0.2) +
  scale_fill_viridis(option = "plasma", name = "% Compulsory Education") +
  labs(
    title = "Distribution of Compulsory Education by MedStat",
    caption = "Source: OFS"
  ) +
  theme_minimal() +
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 12)
  )

# plot secondary
p5 <- ggplot(medstats_geojson_ed) +
  geom_sf(aes(fill = secondary_share), color = "white", size = 0.2) +
  scale_fill_viridis(option = "plasma", name = "% Secondary Education") +
  labs(
    title = "Distribution of Secondary Education by MedStat",
    caption = "Source: OFS"
  ) +
  theme_minimal() +
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 12)
  )

# plot tertiary
p6 <- ggplot(medstats_geojson_ed) +
  geom_sf(aes(fill = tertiary_share), color = "white", size = 0.2) +
  scale_fill_viridis(option = "plasma", name = "% Tertiary Education") +
  labs(
    title = "Distribution of Tertiary Education by MedStat",
    caption = "Source: OFS"
  ) +
  theme_minimal() +
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 12)
  )

file_name_comp <- paste0("figures/medstat_comp_", x, "pdf")
file_name_second <- paste0("figures/medstat_second_", x, "pdf")
file_name_tert <- paste0("figures/medstat_tert_", x, "pdf")

pdf(file = file_name_comp,   # The directory you want to save the file in
    height = 4,
    width = 8) # The height of the plot in inches
plot(p4)
dev.off()

pdf(file = file_name_second,   # The directory you want to save the file in
    height = 4,
    width = 8) # The height of the plot in inches
plot(p5)
dev.off()

pdf(file = file_name_tert,   # The directory you want to save the file in
    height = 4,
    width = 8) # The height of the plot in inches
plot(p6)

dev.off()
}