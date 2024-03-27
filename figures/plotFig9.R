library(sf)
library(scales)
library(dplyr)
library(tidyr)
library(corrplot)
library(ggplot2)
library(cowplot)
library(viridis)


# get full dataset and derive mean values per crop to calculate anomalies
df = read.csv("./data/processed/all_indicators_on_exposure.csv") %>% select(-X)
df = df %>% filter(crop != "summer_canola")

colnames(df)

# check for characteristic NDVI and LST/NDVI values per crop
df %>% group_by(crop) %>% summarize(lstndvi_mean = mean(lstndvi, na.rm=T),
                                            lstndvi_anom_mean = mean(lstndvi_anom, na.rm=T) %>% round(1))


x11()
df = df %>% select("area_iacs", "AZL", "TWI", "NFK",
                   "LST", "NDVI", "NDVI_anom", "LSTNDVI", "LSTNDVI_anom", 
                   "SPEI_mar", "SPEI_apr", "SPEI_may", "SPEI_jun", "SPEI_jul", "SPEI_magnitude",
                   "SMI_mar", "SMI_apr", "SMI_may", "SMI_jun", "SMI_jul", "SMI_magnitude", "SMI_total")

colnames(df) = c("Field Size", "AZL", "TWI", "NFK", "LST", "NDVI", "NDVI Anom",
                 "LST/NDVI", "LST/NDVI Anom", "SPEI March", "SPEI April",
                 "SPEI May", "SPEI June", "SPEI July", "SPEI Magnitude",
                 "SMI March", "SMI April", "SMI May", "SMI June", "SMI July",
                 "SMI Magnitude", "SMI Total")
# correlation matrix on field level
corr = cor(df, use="pairwise.complete.obs")
#pvals = cor.mtest(df, conf.level = 0.95, use="pairwise.complete.obs")

png("./figures/fig9.png", width=10, height=10, res=300, unit="cm", antialias="cleartype", pointsize=7)
#corrplot(corr, tl.col="black", method="number", tl.cex = 0.7, number.cex = 0.7, p.mat=pvals$p, sig.level=0.05)
corrplot.mixed(corr, upper="square", tl.col="black", tl.cex = 0.7, number.cex = 0.45, tl.pos="lt")
dev.off()
