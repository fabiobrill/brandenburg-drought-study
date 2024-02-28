library(sf)
library(dplyr)
library(tidyr)
library(scales)
library(ggplot2)

setwd("./figures")

# required data
# all_indicators_on_exposure.csv
# reported_yieldloss.shp
# loss_table.csv
# cropmodel_results_merged.gpkg | only use wheat anyway?


# --- load data, using MEAN OF BB ON FIELDS? or raster mean? area-weighted?
indicators_on_exposure = read.csv("../data/processed/all_indicators_on_exposure.csv")
loss = read.csv("../data/processed/loss_table.csv")
cropmodel = read.csv("../data/processed/cropmodel_wheat.csv")
#cropmodel = read_sf("../data/processed/cropmodel_results_merged.gpkg")
#reported_impacts = read_sf("reported_yieldloss.shp") 
reported_impacts = read.csv("../data/processed/newspaper_yieldloss.csv")
reported_impacts = reported_impacts %>% group_by(year) %>% 
                   summarise(impact_score = sum(impactscore))

#reported_impacts = reported_impacts %>% 
#                    as.data.frame() %>% 
#                    filter(NUTS_ID == "DE40") %>% 
#                    select(year_date, MIS) %>% 
#                    group_by(year=year_date) %>%
#                    summarize(impact_score = sum(MIS))

# do stuff about the loss table
loss = loss %>% select(-X, -NUTS_NAME, -NUTS_ID)
loss_bb = loss %>% colSums(na.rm = T) %>% as.data.frame()
colnames(loss_bb) = "Loss_Estimate"
rownames(loss_bb) = gsub("loss", "", rownames(loss_bb))
loss_bb$year = as.numeric(rownames(loss_bb))

# area-weighted means of indicator values
fieldmeans = indicators_on_exposure %>% 
                group_by(year) %>% 
                summarize(LSTNDVI = weighted.mean(LSTNDVI_anom, area_iacs, na.rm=T),
                          SMI_total = weighted.mean(SMI_total, area_iacs, na.rm=T),
                          SPEI_magnitude = weighted.mean(SPEI_magnitude, area_iacs, na.rm=T))

# normalize the fieldmeans to plot them on the same axis
fieldmeans$LSTNDVI = rescale(fieldmeans$LSTNDVI, to=c(-1,1))
fieldmeans$SMI_Total = rescale(fieldmeans$SMI_total, to=c(0,1))
fieldmeans$SPEI_Magnitude = rescale(fieldmeans$SPEI_magnitude, to=c(-1,0))

# currently 2021 and 2022 are dummy data
#fieldmeans$SMI_total[c(9,10)] = NA

# Crop model for wheat? mean of 4 crops?
#cropmodel = read_sf("crop_model/cropmodel_results_merged.gpkg") %>% as.data.frame
cropmodel$modelled_gap = cropmodel$modelled_yield_pp - cropmodel$modelled_yield_wlp
cropmodel = cropmodel %>% filter(crop=="winter_wheat") %>% 
                          select(year, modelled_gap) %>%
                          group_by(year) %>%
                          summarize(Modelled_Gap_Wheat = sum(modelled_gap, na.rm=T))

# --- Merge and convert to long format
data = left_join(fieldmeans, loss_bb)
data = left_join(data, reported_impacts)
data = left_join(data, cropmodel)
longdata = pivot_longer(data, cols=2:ncol(data), names_to="Indicator")

# --- define colors
mycols = c("SPEI_Magnitude" = "#f2ce04",
           "LSTNDVI" = "#d00adb",
           "SMI_Total" = "tomato",
           "Loss_Estimate" = "#0a47c0",
           "Modelled_Gap_Wheat" = "forestgreen")

mylinetypes = c("SPEI_Magnitude" = "dashed",
                "LSTNDVI" = "dotted",
                "SMI_Total" = "twodash",
                "Loss_Estimate" = "solid",
                "Modelled_Gap_Wheat" = "longdash")


mycols = c("SPEI_magnitude" = "#dbcd815e",
           "LSTNDVI" = "#ba83bc",
           "SMI_total" = "#834035",
           "loss_estimate" = "#466ab3",
           "Modelled_gap" = "#396a39")
# --- plotting function
x11()
#jpeg("fig1.jpg", width = 760, height = 440, quality=100)
jpeg("fig1.jpg", width = 1400, height = 880, quality=100, type="cairo", antialias="subpixel")
ggplot() +geom_col(aes(year, value), fill="ivory3", data=(longdata %>% filter(Indicator=="impact_score"))) +
          geom_line(aes(year, value, col=Indicator, linetype=Indicator), size=1.5, data=(longdata %>% filter(Indicator == "Loss_Estimate"))) +
          geom_line(aes(year, value*150, col=Indicator, linetype=Indicator), size=1.5, data=(longdata %>% filter(Indicator == "SPEI_Magnitude"))) +
          geom_line(aes(year, value*150, col=Indicator, linetype=Indicator), size=1.5, data=(longdata %>% filter(Indicator == "LSTNDVI"))) +
          geom_line(aes(year, value*150, col=Indicator, linetype=Indicator), size=1.5, data=(longdata %>% filter(Indicator == "SMI_Total"))) +
          geom_line(aes(year, value/50000, col=Indicator, linetype=Indicator), size=1.5, data=(longdata %>% filter(Indicator == "Modelled_Gap_Wheat"))) +
          scale_y_continuous(sec.axis = sec_axis(~./150, name="Normalized SPEI-Magn. | SMI-Total | LST/NDVI-Anom.")) +
          #annotate("rect", xmin = 2012.5, xmax = 2017.5, ymin = -150, ymax = 150, alpha = .3,fill = "#c4e3fa06") +
          annotate("rect", xmin = 2017.5, xmax = 2022, ymin = -150, ymax = 150, alpha = .3,fill = "#ffeabc06") +
          scale_color_manual(values=mycols) +
          scale_linetype_manual(values=mylinetypes) +
          ylab("Loss Estimate [M€] | # Newspaper Reports") +
          xlab("") +
          scale_x_continuous(breaks = 2013:2022) +
          theme_bw(base_size = 32) +
          theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1, size=rel(1.05)), legend.position = "bottom") +
          theme(axis.title.y = element_text(size=rel(0.8)))
dev.off()
