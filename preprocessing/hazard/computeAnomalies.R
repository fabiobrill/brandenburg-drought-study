library(sf)
library(dplyr)
library(tidyr)
library(ggplot2)

# peak below threshold
pbt = function(spei, th = -0.5){
    return(ifelse(spei < th, spei, 0))
}

# including July to be consistent with SMI
deriveMagnitude = function(df){
    return(pbt(df$SPEI_mar) + pbt(df$SPEI_apr) + pbt(df$SPEI_may) + pbt(df$SPEI_jun) + pbt(df$SPEI_jul))
}

# get full dataset and derive mean values per crop to calculate anomalies
df = read.csv("./data/intermediate/indicators_per_nuts3.csv")

# calculate mean and area-weighted mean of the indicators
# the area-weighted version accounts for differences in field size
means_per_crop = df %>%
    select(year, crop, LST, NDVI, LSTNDVI, AZL, TWI, NFK, area_iacs) %>%
    group_by(crop) %>%
    summarize(
        AZL_m = mean(AZL, na.rm=T),
        AZL_wm = weighted.mean(AZL, area_iacs, na.rm=T),
        TWI_m = mean(TWI, na.rm=T),
        TWI_wm = weighted.mean(TWI, area_iacs, na.rm=T),
        NFK_m = mean(NFK, na.rm=T),
        NFK_wm = weighted.mean(NFK, area_iacs, na.rm=T),
        LST_m = mean(LST, na.rm=T),
        LST_wm = weighted.mean(LST, area_iacs, na.rm=T),
        NDVI_m = mean(NDVI, na.rm=T),
        NDVI_wm = weighted.mean(NDVI, area_iacs, na.rm=T),
        LSTNDVI_m = mean(LSTNDVI, na.rm=T),
        LSTNDVI_wm = weighted.mean(LSTNDVI, area_iacs, na.rm=T)
    )
write.csv(means_per_crop, "./data/processed/means_per_crop.csv", row.names=F)

# compute anomalies based on the area-weighted means per crop
anomalies = df %>%
    select(year, crop, LST, NDVI, LSTNDVI) %>%
    left_join(means_per_crop) %>% 
    transmute(
        year = year,
        crop = crop,
        LST_anom = ((LST-LST_wm)/LST_wm),
        NDVI_anom = ((NDVI-NDVI_wm)/NDVI_wm),
        LSTNDVI_anom = ((LSTNDVI-LSTNDVI_wm)/LSTNDVI_wm))

df$LST_anom = anomalies$LST_anom
df$NDVI_anom = anomalies$NDVI_anom
df$LSTNDVI_anom = anomalies$LSTNDVI_anom
df$SPEI_magnitude = deriveMagnitude(df)

# this is identical to the data in df, only with additional geometry
shapes = read_sf("./data/intermediate/indicators_per_nuts3.gpkg")
shapes$LST_anom = df$LST_anom
shapes$NDVI_anom = df$NDVI_anom
shapes$LSTNDVI_anom = df$LSTNDVI_anom
shapes$SPEI_magnitude = df$SPEI_magnitude

write.csv(df, "./data/processed/all_indicators_on_exposure.csv", row.names=F)
write_sf(shapes, "./data/processed/all_indicators_on_exposure.gpkg", row.names=F)