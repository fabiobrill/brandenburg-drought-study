# ----------------------------------------------------------------------------------------------- #
# merge the threshold data in wide format with the relative gaps
# there are two types of features here:
# 1. the absolute area where thresholds are exceeded
# 2. the relative area, i.e. abs / total for the specific crop/year/landkreis
# while (1) is meaningful to predict absolute yield losses [t]
# this will result in learning the different sizes of the Landkreise
# e.g. Uckermark is larger than Frankfurt(Oder) and thus has more area affected
# however (2) should be meaningful to predict relative gaps [%]
# which should allow for training hierarchical models of all crops at the same time

library(sf)
library(dplyr)
library(tidyr)

#setwd("D:/Seafile/Meine Bibliothek/DroughtRiskPaper/data")
setwd("./data/intermediate")

longgaps = read.csv("../processed/relative_gaps_longformat.csv")

# threshold data
thresholds_SPEI = read.csv("impactarea_thresholds_SPEI_monthly.csv")
thresholds_SMI = read.csv("impactarea_thresholds_SMI_monthly.csv")
thresholds_SMI_total = read.csv("impactarea_thresholds_SMI_total.csv")
thresholds_LSTNDVI = read.csv("impactarea_thresholds_LSTNDVI.csv")
thresholds_AZL = read.csv("impactarea_thresholds_AZL.csv")
thresholds_LBG = read.csv("impactarea_thresholds_LBG.csv")

str(thresholds_SPEI)
str(thresholds_SMI_total)
str(thresholds_LSTNDVI)

# ----------------------------------------------------------------------------------------------- #
# very careful here with the hard-coded selection of columns!
# for the relative area thresholds it is different than for absolute values!

# thresholds to broad format
LSTNDVI_wide = pivot_wider(thresholds_LSTNDVI, id_cols = c(1,2,3), names_from = 4, values_from = 6,
                           names_prefix="LSTNDVI_", values_fn = first)

SMI_total_wide = pivot_wider(thresholds_SMI_total, id_cols=c(1,2,3), names_from=4, values_from=6,
                      names_prefix="SMI_total_", values_fn=first)

AZL_wide = pivot_wider(thresholds_AZL, id_cols=c(1,2,3), names_from=4, values_from=6,
                      names_prefix="AZL_", values_fn=first)

LBG_wide = pivot_wider(thresholds_LBG, id_cols=c(1,2,3), names_from=4, values_from=6,
                      names_prefix="LBG_", values_fn=first)
#SPEI_sum_wide = pivot_wider(thresholds_SPEI, id_cols=c(1,2,3), names_from=4, values_from=13,
#                      names_prefix="SPEI_sum_", values_fn=first)

SPEI_magnitude_wide = pivot_wider(thresholds_SPEI, id_cols=c(1,2,3), names_from=4, 
                                  values_from=which(colnames(thresholds_SPEI) == "relimpactarea_magnitude"),
                                  names_prefix="SPEI_magnitude_", values_fn=first)

#SPEI_magnitude_inclJul_wide = pivot_wider(thresholds_SPEI, id_cols=c(1,2,3), names_from=4, values_from=15,
#                      names_prefix="SPEI_magnitude_inclJul_", values_fn=first)

SPEI_mar_wide = pivot_wider(thresholds_SPEI, id_cols=c(1,2,3), names_from=4, 
                            values_from=which(colnames(thresholds_SPEI) == "relimpactarea_mar"),
                            names_prefix="SPEI_mar_", values_fn=first)

SPEI_apr_wide = pivot_wider(thresholds_SPEI, id_cols=c(1,2,3), names_from=4, 
                            values_from=which(colnames(thresholds_SPEI) == "relimpactarea_apr"),
                            names_prefix="SPEI_apr_", values_fn=first)

SPEI_may_wide = pivot_wider(thresholds_SPEI, id_cols=c(1,2,3), names_from=4,
                            values_from=which(colnames(thresholds_SPEI) == "relimpactarea_may"),
                            names_prefix="SPEI_may_", values_fn=first)

SPEI_jun_wide = pivot_wider(thresholds_SPEI, id_cols=c(1,2,3), names_from=4,
                            values_from=which(colnames(thresholds_SPEI) == "relimpactarea_jun"),
                            names_prefix="SPEI_jun_", values_fn=first)

SPEI_jul_wide = pivot_wider(thresholds_SPEI, id_cols=c(1,2,3), names_from=4,
                            values_from=which(colnames(thresholds_SPEI) == "relimpactarea_jul"),
                            names_prefix="SPEI_jul_", values_fn=first)



# SMI
SMI_magnitude_wide = pivot_wider(thresholds_SMI, id_cols=c(1,2,3), names_from=4, 
                                  values_from=which(colnames(thresholds_SMI) == "relimpactarea_magnitude"),
                                  names_prefix="SMI_magnitude_", values_fn=first)

SMI_mar_wide = pivot_wider(thresholds_SMI, id_cols=c(1,2,3), names_from=4, 
                            values_from=which(colnames(thresholds_SMI) == "relimpactarea_mar"),
                            names_prefix="SMI_mar_", values_fn=first)

SMI_apr_wide = pivot_wider(thresholds_SMI, id_cols=c(1,2,3), names_from=4, 
                            values_from=which(colnames(thresholds_SMI) == "relimpactarea_apr"),
                            names_prefix="SMI_apr_", values_fn=first)

SMI_may_wide = pivot_wider(thresholds_SMI, id_cols=c(1,2,3), names_from=4,
                            values_from=which(colnames(thresholds_SMI) == "relimpactarea_may"),
                            names_prefix="SMI_may_", values_fn=first)

SMI_jun_wide = pivot_wider(thresholds_SMI, id_cols=c(1,2,3), names_from=4,
                            values_from=which(colnames(thresholds_SMI) == "relimpactarea_jun"),
                            names_prefix="SMI_jun_", values_fn=first)

SMI_jul_wide = pivot_wider(thresholds_SMI, id_cols=c(1,2,3), names_from=4,
                            values_from=which(colnames(thresholds_SMI) == "relimpactarea_jul"),
                            names_prefix="SMI_jul_", values_fn=first)


dim(SMI_total_wide)
dim(LSTNDVI_wide)

thresholds_merged = full_join(SMI_total_wide, LSTNDVI_wide) %>% 
                    full_join(AZL_wide) %>%
                    full_join(LBG_wide) %>%
                    full_join(SPEI_mar_wide) %>%
                    full_join(SPEI_apr_wide) %>%
                    full_join(SPEI_may_wide) %>% 
                    full_join(SPEI_jun_wide) %>%
                    full_join(SPEI_jul_wide) %>%
                    full_join(SPEI_magnitude_wide) %>%
                    full_join(SMI_mar_wide) %>%
                    full_join(SMI_apr_wide) %>%
                    full_join(SMI_may_wide) %>% 
                    full_join(SMI_jun_wide) %>%
                    full_join(SMI_jul_wide) %>%
                    full_join(SMI_magnitude_wide)

dim(thresholds_merged)
colnames(thresholds_merged)

# add NUTS_ID
thresholds_merged$NUTS_ID = case_when(
 thresholds_merged$NUTS_NAME == 'Barnim' ~ 'DE405', 
 thresholds_merged$NUTS_NAME == 'Brandenburg an der Havel, Kreisfreie Stadt' ~ 'DE401', 
 thresholds_merged$NUTS_NAME == 'Cottbus, Kreisfreie Stadt' ~ 'DE402',
 thresholds_merged$NUTS_NAME == 'Dahme-Spreewald' ~ 'DE406',
 thresholds_merged$NUTS_NAME == 'Elbe-Elster' ~ 'DE407',
 thresholds_merged$NUTS_NAME == 'Frankfurt (Oder), Kreisfreie Stadt' ~ 'DE403',
 thresholds_merged$NUTS_NAME == 'Havelland' ~ 'DE408',
 endsWith(thresholds_merged$NUTS_NAME, '-Oderland') ~ 'DE409',
 thresholds_merged$NUTS_NAME == 'Oberhavel' ~ 'DE40A',
 thresholds_merged$NUTS_NAME == 'Oberspreewald-Lausitz' ~ 'DE40B',
 thresholds_merged$NUTS_NAME == 'Oder-Spree' ~ 'DE40C',
 thresholds_merged$NUTS_NAME == 'Ostprignitz-Ruppin' ~ 'DE40D',
 thresholds_merged$NUTS_NAME == 'Potsdam-Mittelmark' ~ 'DE40E',
 thresholds_merged$NUTS_NAME == 'Potsdam, Kreisfreie Stadt' ~ 'DE404',
 thresholds_merged$NUTS_NAME == 'Prignitz' ~ 'DE40F',
 startsWith(thresholds_merged$NUTS_NAME, 'Spree-Nei') ~ 'DE40G',
 startsWith(thresholds_merged$NUTS_NAME, 'Teltow-Fl') ~ 'DE40H',
 thresholds_merged$NUTS_NAME == 'Uckermark' ~ 'DE40I'
)

write.csv(thresholds_merged, "../processed/thresholds_all.csv", row.names=F)
# ----------------------------------------------------------------------------------------------- #

thresholds_merged$NUTS_NAME = NULL
thresholds_vs_gaps = left_join(thresholds_merged, longgaps)

write.csv(thresholds_vs_gaps, "../processed/relative_gaps_vs_thresholds.csv", row.names=F)
