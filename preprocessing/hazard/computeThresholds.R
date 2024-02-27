# ----------------------------------------------------------------------------------------------- #
# calculate area-weighted number of fields that exceed a threshold of feature values
# can be used as predictive features for yield gaps on county level

library(sf)
library(dplyr)

setwd("./data/intermediate")

# read full field-level dataset. still contains summer canola, which is removed here
data = read.csv("../processed/all_indicators_on_exposure.csv") %>% filter(crop != "summer_canola")

# ----------------------------------------------------------------------------------------------- #
# this part is written in hard-coded nested loops - probably inefficient, only needed once, though
# the loops are 'yoi' ~ year of interest, 'lkoi' ~ landkreis of interest, 'coi' ~ crop of interest

impacted = data.frame()

for(yoi in 2013:2022){
    for(lkoi in unique(data$NUTS_NAME)){
        for(coi in unique(data$crop)){
            print(paste(yoi, lkoi, coi, sep="|"))
            specific_area = data %>% dplyr::filter(year == yoi, NUTS_NAME == lkoi, crop == coi) %>% 
                                           select(area_iacs) %>%
                                           sum(na.rm=T)
            for(threshold in seq(0.25, 1.5, 0.25)){
                temp = data %>% select(year, NUTS_NAME, crop, area_iacs, LSTNDVI_anom) %>% 
                                      dplyr::filter(year == yoi, NUTS_NAME == lkoi, crop == coi)
                temp$impacted = temp$LSTNDVI_anom > threshold
                temp$impactarea = temp$impacted * temp$area_iacs
                temp$relimpactarea = temp$impactarea / specific_area
                impacted = rbind(impacted, cbind(year = yoi,
                                                 NUTS_NAME = lkoi,
                                                 crop = coi,
                                                 threshold_LSTNDVI = threshold,
                                                 impactarea_LSTNDVI = sum(temp$impactarea, na.rm=T),
                                                 relimpactarea_LSTNDVI = sum(temp$relimpactarea, na.rm=T)))
            }
        }
    }
}

impacted$year = as.integer(impacted$year)
impacted$threshold_LSTNDVI = as.numeric(impacted$threshold_LSTNDVI)
impacted$impactarea_LSTNDVI = as.numeric(impacted$impactarea_LSTNDVI)
impacted$relimpactarea_LSTNDVI = as.numeric(impacted$relimpactarea_LSTNDVI)

write.csv(impacted, "impactarea_thresholds_LSTNDVI.csv", row.names=F)

# ----------------------------------------------------------------------------------------------- #
# same for UFZ SMI_total
impacted = data.frame()

for(yoi in 2013:2022){
    for(lkoi in unique(data$NUTS_NAME)){
        for(coi in unique(data$crop)){
            print(paste(yoi, lkoi, coi, sep="|"))
            specific_area = data %>% dplyr::filter(year == yoi, NUTS_NAME == lkoi, crop == coi) %>% select(area_iacs) %>% sum(na.rm=T)
            for(threshold in c(0, 5, 10, 15, 20, 25, 30, 35)){
                temp = data %>% select(year, NUTS_NAME, crop, area_iacs, SMI_total) %>% dplyr::filter(year == yoi, NUTS_NAME == lkoi, crop == coi)
                temp$impacted = temp$SMI_total > threshold
                temp$impactarea = temp$impacted * temp$area_iacs
                temp$relimpactarea = temp$impactarea / specific_area
                impacted = rbind(impacted, cbind(year = yoi,
                                                 NUTS_NAME = lkoi,
                                                 crop = coi,
                                                 threshold_SMI_total = threshold,
                                                 impactarea_SMI_total = sum(temp$impactarea, na.rm=T),
                                                 relimpactarea_SMI_total = sum(temp$relimpactarea, na.rm=T)))
            }
        }
    }
}

impacted$year = as.integer(impacted$year)
impacted$threshold_SMI_total = as.numeric(impacted$threshold_SMI_total)
impacted$impactarea_SMI_total = as.numeric(impacted$impactarea_SMI_total)
impacted$relimpactarea_SMI_total = as.numeric(impacted$relimpactarea_SMI_total)

str(impacted)
write.csv(impacted, "impactarea_thresholds_SMI_total.csv", row.names=F)

# ----------------------------------------------------------------------------------------------- #
# same for monthly SMI

impacted = data.frame()

for(yoi in 2013:2022){
    for(lkoi in unique(data$NUTS_NAME)){
        for(coi in unique(data$crop)){
            print(paste(yoi, lkoi, coi, sep="|"))
            specific_area = data %>% dplyr::filter(year == yoi, NUTS_NAME == lkoi, crop == coi) %>%
                                           select(area_iacs) %>%
                                           sum(na.rm=T)
            for(threshold in seq(0, 0.15, 0.05)){
                temp = data %>% select(year, NUTS_NAME, crop, area_iacs, SMI_magnitude,
                                             SMI_mar, SMI_apr, SMI_may, SMI_jun, SMI_jul) %>% 
                                             dplyr::filter(year == yoi, NUTS_NAME == lkoi, crop == coi)
                temp$impacted_magnitude = temp$SMI_magnitude > threshold
                temp$impacted_mar = temp$SMI_mar > threshold
                temp$impacted_apr = temp$SMI_apr > threshold
                temp$impacted_may = temp$SMI_may > threshold
                temp$impacted_jun = temp$SMI_jun > threshold
                temp$impacted_jul = temp$SMI_jul > threshold
                temp$impactarea_magnitude = temp$impacted_magnitude * temp$area_iacs
                temp$impactarea_mar = temp$impacted_mar * temp$area_iacs
                temp$impactarea_apr = temp$impacted_apr * temp$area_iacs
                temp$impactarea_may = temp$impacted_may * temp$area_iacs
                temp$impactarea_jun = temp$impacted_jun * temp$area_iacs
                temp$impactarea_jul = temp$impacted_jul * temp$area_iacs
                temp$relimpactarea_magnitude = temp$impactarea_magnitude / specific_area
                temp$relimpactarea_mar = temp$impactarea_mar / specific_area
                temp$relimpactarea_apr = temp$impactarea_apr / specific_area
                temp$relimpactarea_may = temp$impactarea_may / specific_area
                temp$relimpactarea_jun = temp$impactarea_jun / specific_area
                temp$relimpactarea_jul = temp$impactarea_jul / specific_area
                impacted = rbind(impacted, cbind(year = yoi,
                                                 NUTS_NAME = lkoi,
                                                 crop = coi,
                                                 threshold_SMI = threshold,
                                                 impactarea_magnitude = sum(temp$impactarea_magnitude, na.rm=T),
                                                 impactarea_mar = sum(temp$impactarea_mar, na.rm=T),
                                                 impactarea_apr = sum(temp$impactarea_apr, na.rm=T),
                                                 impactarea_may = sum(temp$impactarea_may, na.rm=T),
                                                 impactarea_jun = sum(temp$impactarea_jun, na.rm=T),
                                                 impactarea_jul = sum(temp$impactarea_jul, na.rm=T),
                                                 relimpactarea_magnitude = sum(temp$relimpactarea_magnitude, na.rm=T),
                                                 relimpactarea_mar = sum(temp$relimpactarea_mar, na.rm=T),
                                                 relimpactarea_apr = sum(temp$relimpactarea_apr, na.rm=T),
                                                 relimpactarea_may = sum(temp$relimpactarea_may, na.rm=T),
                                                 relimpactarea_jun = sum(temp$relimpactarea_jun, na.rm=T),
                                                 relimpactarea_jul = sum(temp$relimpactarea_jul, na.rm=T)))
            }
        }
    }
}
impacted$year = as.integer(impacted$year)
impacted$threshold_SMI = as.numeric(impacted$threshold_SMI)
impacted$impactarea_magnitude = as.numeric(impacted$impactarea_magnitude)
impacted$impactarea_mar = as.numeric(impacted$impactarea_mar)
impacted$impactarea_apr = as.numeric(impacted$impactarea_apr)
impacted$impactarea_may = as.numeric(impacted$impactarea_may)
impacted$impactarea_jun = as.numeric(impacted$impactarea_jun)
impacted$impactarea_jul = as.numeric(impacted$impactarea_jul)
impacted$relimpactarea_magnitude = as.numeric(impacted$relimpactarea_magnitude)
impacted$relimpactarea_mar = as.numeric(impacted$relimpactarea_mar)
impacted$relimpactarea_apr = as.numeric(impacted$relimpactarea_apr)
impacted$relimpactarea_may = as.numeric(impacted$relimpactarea_may)
impacted$relimpactarea_jun = as.numeric(impacted$relimpactarea_jun)
impacted$relimpactarea_jul = as.numeric(impacted$relimpactarea_jul)

str(impacted)
write.csv(impacted, "impactarea_thresholds_SMI_monthly.csv", row.names=F)

# ----------------------------------------------------------------------------------------------- #
# same for SPEI

impacted = data.frame()

for(yoi in 2013:2022){
    for(lkoi in unique(data$NUTS_NAME)){
        for(coi in unique(data$crop)){
            print(paste(yoi, lkoi, coi, sep="|"))
            specific_area = data %>% dplyr::filter(year == yoi, NUTS_NAME == lkoi, crop == coi) %>% select(area_iacs) %>% sum(na.rm=T)
            for(threshold in seq(-4, 0, 0.5)){
                temp = data %>% select(year, NUTS_NAME, crop, area_iacs, SPEI_magnitude,
                                             SPEI_mar, SPEI_apr, SPEI_may, SPEI_jun, SPEI_jul) %>% 
                                             dplyr::filter(year == yoi, NUTS_NAME == lkoi, crop == coi)
                temp$impacted_magnitude = temp$SPEI_magnitude < threshold
                temp$impactarea_magnitude = temp$impacted_magnitude * temp$area_iacs
                temp$relimpactarea_magnitude = temp$impactarea_magnitude / specific_area
                temp$impacted_mar = temp$SPEI_mar < threshold
                temp$impactarea_mar = temp$impacted_mar * temp$area_iacs
                temp$relimpactarea_mar = temp$impactarea_mar / specific_area
                temp$impacted_apr = temp$SPEI_apr < threshold
                temp$impactarea_apr = temp$impacted_apr * temp$area_iacs
                temp$relimpactarea_apr = temp$impactarea_apr / specific_area
                temp$impacted_may = temp$SPEI_may < threshold
                temp$impactarea_may = temp$impacted_may * temp$area_iacs
                temp$relimpactarea_may = temp$impactarea_may / specific_area
                temp$impacted_jun = temp$SPEI_jun < threshold
                temp$impactarea_jun = temp$impacted_jun * temp$area_iacs
                temp$relimpactarea_jun = temp$impactarea_jun / specific_area
                temp$impacted_jul = temp$SPEI_jul < threshold
                temp$impactarea_jul = temp$impacted_jul * temp$area_iacs
                temp$relimpactarea_jul = temp$impactarea_jul / specific_area
                impacted = rbind(impacted, cbind(year = yoi,
                                                 NUTS_NAME = lkoi,
                                                 crop = coi,
                                                 threshold_SPEI = threshold,
                                                 impactarea_magnitude = sum(temp$impactarea_magnitude, na.rm=T),
                                                 impactarea_mar = sum(temp$impactarea_mar, na.rm=T),
                                                 impactarea_apr = sum(temp$impactarea_apr, na.rm=T),
                                                 impactarea_may = sum(temp$impactarea_may, na.rm=T),
                                                 impactarea_jun = sum(temp$impactarea_jun, na.rm=T),
                                                 impactarea_jul = sum(temp$impactarea_jul, na.rm=T),
                                                 relimpactarea_magnitude = sum(temp$relimpactarea_magnitude, na.rm=T),
                                                 relimpactarea_mar = sum(temp$relimpactarea_mar, na.rm=T),
                                                 relimpactarea_apr = sum(temp$relimpactarea_apr, na.rm=T),
                                                 relimpactarea_may = sum(temp$relimpactarea_may, na.rm=T),
                                                 relimpactarea_jun = sum(temp$relimpactarea_jun, na.rm=T),
                                                 relimpactarea_jul = sum(temp$relimpactarea_jul, na.rm=T)))
            }
        }
    }
}

impacted$year = as.integer(impacted$year)
impacted$threshold_SPEI = as.numeric(impacted$threshold_SPEI)
impacted$impactarea_magnitude = as.numeric(impacted$impactarea_magnitude)
impacted$impactarea_mar = as.numeric(impacted$impactarea_mar)
impacted$impactarea_apr = as.numeric(impacted$impactarea_apr)
impacted$impactarea_may = as.numeric(impacted$impactarea_may)
impacted$impactarea_jun = as.numeric(impacted$impactarea_jun)
impacted$impactarea_jul = as.numeric(impacted$impactarea_jul)
impacted$relimpactarea_magnitude = as.numeric(impacted$relimpactarea_magnitude)
impacted$relimpactarea_mar = as.numeric(impacted$relimpactarea_mar)
impacted$relimpactarea_apr = as.numeric(impacted$relimpactarea_apr)
impacted$relimpactarea_may = as.numeric(impacted$relimpactarea_may)
impacted$relimpactarea_jun = as.numeric(impacted$relimpactarea_jun)
impacted$relimpactarea_jul = as.numeric(impacted$relimpactarea_jul)

str(impacted)
summary(impacted)
write.csv(impacted, "impactarea_thresholds_SPEI_monthly.csv", row.names=F)


# ----------------------------------------------------------------------------------------------- #
# same for Ackerzahl, using the LBG thresholds
# should this be intervals or cummulative??

impacted = data.frame()

for(yoi in 2013:2022){
    for(lkoi in unique(data$NUTS_NAME)){
        for(coi in unique(data$crop)){
            print(paste(yoi, lkoi, coi, sep="|"))
            specific_area = data %>% dplyr::filter(year == yoi, NUTS_NAME == lkoi, crop == coi) %>%
                                           select(area_iacs) %>%
                                           sum(na.rm=T)
            for(threshold in c(23, 29, 36, 46)){
                temp = data %>% select(year, NUTS_NAME, crop, area_iacs, AZL) %>%
                                      dplyr::filter(year == yoi, NUTS_NAME == lkoi, crop == coi)
                temp$impacted = temp$AZL < threshold
                temp$impactarea = temp$impacted * temp$area_iacs
                temp$relimpactarea = temp$impactarea / specific_area
                impacted = rbind(impacted, cbind(year = yoi,
                                                 NUTS_NAME = lkoi,
                                                 crop = coi,
                                                 threshold_AZL = threshold,
                                                 impactarea_AZL = sum(temp$impactarea, na.rm=T),
                                                 relimpactarea_AZL = sum(temp$relimpactarea, na.rm=T)))
            }
        }
    }
}

impacted$year = as.integer(impacted$year)
impacted$threshold_AZL = as.numeric(impacted$threshold_AZL)
impacted$impactarea_AZL = as.numeric(impacted$impactarea_AZL)
impacted$relimpactarea_AZL = as.numeric(impacted$relimpactarea_AZL)

str(impacted)
write.csv(impacted, "impactarea_thresholds_AZL.csv", row.names=F)



# LBG intervals

impacted = data.frame()

for(yoi in 2013:2022){
    for(lkoi in unique(data$NUTS_NAME)){
        for(coi in unique(data$crop)){
            print(paste(yoi, lkoi, coi, sep="|"))
            specific_area = data %>% dplyr::filter(year == yoi, NUTS_NAME == lkoi, crop == coi) %>%
                                           select(area_iacs) %>%
                                           sum(na.rm=T)
            for(threshold in 1:5){
                temp = data %>% select(year, NUTS_NAME, crop, area_iacs, LBG) %>%
                                      dplyr::filter(year == yoi, NUTS_NAME == lkoi, crop == coi)
                temp$impacted = temp$LBG == threshold
                temp$impactarea = temp$impacted * temp$area_iacs
                temp$relimpactarea = temp$impactarea / specific_area
                impacted = rbind(impacted, cbind(year = yoi,
                                                 NUTS_NAME = lkoi,
                                                 crop = coi,
                                                 threshold_LBG = threshold,
                                                 impactarea_LBG = sum(temp$impactarea, na.rm=T),
                                                 relimpactarea_LBG = sum(temp$relimpactarea, na.rm=T)))
            }
        }
    }
}

impacted$year = as.integer(impacted$year)
impacted$threshold_LBG = as.numeric(impacted$threshold_LBG)
impacted$impactarea_LBG = as.numeric(impacted$impactarea_LBG)
impacted$relimpactarea_LBG = as.numeric(impacted$relimpactarea_LBG)

str(impacted)
write.csv(impacted, "impactarea_thresholds_LBG.csv", row.names=F)
