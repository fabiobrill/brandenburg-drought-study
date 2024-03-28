library(sf)
library(dplyr)
library(tidyr)
library(scales)
library(ggplot2)

setwd("./figures")

# --- load data, using MEAN OF BB ON FIELDS? or raster mean? area-weighted?
indicators_on_exposure = read.csv("../data/processed/all_indicators_on_exposure.csv")
loss = read.csv("../data/processed/loss_table.csv")
cropmodel = read.csv("../data/processed/cropmodel_wheat.csv")
reported_impacts = read.csv2("../data/processed/impactcount_sodoge_etal.csv")
colnames(reported_impacts)[2] = "n_articles"

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

# Crop model for wheat? mean of 4 crops?
#cropmodel = read_sf("crop_model/cropmodel_results_merged.gpkg") %>% as.data.frame
cropmodel$modelled_gap = cropmodel$modelled_yield_pp - cropmodel$modelled_yield_wlp
cropmodel = cropmodel %>% filter(crop=="winter_wheat") %>% 
                          select(year, modelled_gap) %>%
                          group_by(year) %>%
                          summarize(Modelled_Gap_Wheat = sum(modelled_gap, na.rm=T))
cropmodel$Modelled_Gap_Wheat = rescale(cropmodel$Modelled_Gap_Wheat, to=c(0,1))

# --- Merge and convert to long format
data = left_join(fieldmeans, loss_bb)
data = left_join(data, reported_impacts)
data = left_join(data, cropmodel)
longdata = pivot_longer(data, cols=2:ncol(data), names_to="Indicator")

# --- define colors
mycols = c("Loss_Estimate" = "#0a47c0",
           "SPEI_Magnitude" = "#f2ce04",
           "SMI_Total" = "tomato",
           "LSTNDVI" = "#d00adb",
           "Modelled_Gap_Wheat" = "forestgreen")

mylinetypes = c("Loss_Estimate" = "solid",
                "SPEI_Magnitude" = "dashed",
                "SMI_Total" = "twodash",
                "LSTNDVI" = "dotted",
                "Modelled_Gap_Wheat" = "longdash")

mylabels = c(n_articles = "Newspaper Reports",
             Loss_Estimate = "Loss Estimate",
             SPEI_Magnitude = "SPEI Magnitude",
             SMI_Total = "SMI Total",
             LSTNDVI = "LST/NDVI Anom.",
             Modelled_Gap_Wheat = "Modelled Gap Wheat")

# --- plotting function
#x11()
jpeg("fig4.jpg", width = 1400, height = 760, quality=100, type="cairo", antialias="subpixel")
#pdf("fig4.pdf", width = 1400, height = 760)
ggplot() +geom_col(aes(year, value, fill=Indicator), data=(longdata %>% filter(Indicator=="n_articles"))) +
          geom_line(aes(year, value, col=Indicator, linetype=Indicator), size=1.5, data=(longdata %>% filter(Indicator == "Loss_Estimate"))) +
          geom_line(aes(year, value*150, col=Indicator, linetype=Indicator), size=1.5, data=(longdata %>% filter(Indicator == "SPEI_Magnitude"))) +
          geom_line(aes(year, value*150, col=Indicator, linetype=Indicator), size=1.5, data=(longdata %>% filter(Indicator == "LSTNDVI"))) +
          geom_line(aes(year, value*150, col=Indicator, linetype=Indicator), size=1.5, data=(longdata %>% filter(Indicator == "SMI_Total"))) +
          geom_line(aes(year, value*150, col=Indicator, linetype=Indicator), size=1.5, data=(longdata %>% filter(Indicator == "Modelled_Gap_Wheat"))) +
          scale_y_continuous(sec.axis = sec_axis(~./150, name="Normalized SPEI Magnitude | SMI Total | \n LST/NDVI Anom. | Modelled Gap Wheat")) +
          annotate("rect", xmin = 2017.5, xmax = 2022.5, ymin = -150, ymax = 150, alpha = .3,fill = "#ffeabc06") +
          scale_fill_manual(values="ivory3", labels=mylabels)+
          scale_color_manual(values=mycols, labels=mylabels) +
          scale_linetype_manual(values=mylinetypes, labels=mylabels) +
          ylab("Loss Estimate [M€] | Newspaper Reports [count]") +
          xlab("") +
          scale_x_continuous(breaks = 2013:2022) +
          theme_bw(base_size = 26) +
          theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1, size=rel(1.05)), legend.position = "bottom") +
          theme(axis.title.y = element_text(size=rel(0.8))) +
          theme(legend.title=element_blank(), legend.key.size=unit(3,"lines"))
dev.off()