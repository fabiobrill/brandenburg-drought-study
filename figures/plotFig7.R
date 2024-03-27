library(ggplot2)
library(dplyr)
library(sf)

setwd("./data/processed/")

# load relative gap data and county names (as labels)
longgaps = read.csv("relative_gaps_longformat.csv")
counties = read_sf("brandenburg_landkreise_id_25833.gpkg")
colnames(counties)[colnames(counties)=="krs_name"] = "County"
counties = counties %>% as.data.frame() %>% select(County, NUTS_ID)

longgaps = left_join(longgaps, counties)
dim(longgaps)

# 2160 potential data points - however, 30% is NA (crop does not exist in county/year)
# there are 3 entries in the yield reports for Potatoes in Barnim (2013, 2014, 2017)
# where an area of 0 is reported together with an unreasonable amount of yield
# this leads to 3 outliers in the relative gap data, which are removed here
longgaps %>% filter(rel_gap > 1) # 17, 23
longgaps %>% filter(rel_gap < -1) # -inf

# for the plot it is important to keep the NA's though
longgaps$rel_gap[longgaps$rel_gap > 1] = NA
longgaps$rel_gap[longgaps$rel_gap < -1] = NA
dim(longgaps)

colmapping = c("Brandenburg an der Havel" = "dodgerblue2",
               "Cottbus" = "#E31A1C",
               "Frankfurt (Oder)" = "green4",
               "Potsdam" = "#6A3D9A",
               "Barnim" = "#FF7F00",
               "Dahme-Spreewald" = "gold1",
               "Elbe-Elster" = "skyblue2",
               "Havelland" = "#FB9A99",
               "Märkisch-Oderland" = "khaki2",
               "Oberhavel" = "maroon",
               "Oberspreewald-Lausitz" = "steelblue4",
               "Oder-Spree" = "darkorange4",
               "Ostprignitz-Ruppin" = "palegreen2",
               "Potsdam-Mittelmark" = "darkturquoise",
               "Prignitz" = "deeppink1",
               "Spree-Neiße" ="blue1",
               "Teltow-Fläming" = "yellow3",
               "Uckermark" = "yellow4"
)

# Crop names for facet labels
croplabels = c("Grain Maize", "Lupines", "Oat", "Peas", "Potatoes",
               "Rye", "Sugar Beet", "Sunflower", "Triticale",
               "Winter Barley", "Winter Canola", "Winter Wheat")
names(croplabels) = c("grain_maize", "lupines", "oat", "peas", "potatoes",
                      "rye", "sugarbeet", "sunflower", "triticale", 
                      "winter_barley", "winter_canola", "winter_wheat")

#x11()
jpeg("../../figures/fig7.jpg", width = 1100, height = 800, quality=100, type="cairo", antialias = "subpixel")
ggplot(longgaps) + geom_line(aes(year, rel_gap, col=County)) +
                   facet_wrap(~crop, labeller = labeller(crop=croplabels)) +
                   #geom_hline(yintercept = 0, col="#00000055") +
                   #geom_vline(xintercept = 2018, col="orange") +
                   scale_color_manual(values=colmapping) +
                   scale_y_continuous("Relative Yield Gap", breaks=c(-1, -0.5, 0, 0.5, 1),
                                      labels=c("-100%", "-50%", "0%", "50%", "100%")) +
                   scale_x_continuous("", breaks=2013:2022, labels=2013:2022, minor_breaks=2013:2022) +
                   theme_bw(base_size = 20) +
                   theme(legend.position = "bottom", legend.title=element_blank(),
                         strip.background = element_rect(fill="#a5adff"),
                         axis.text.x = element_text(angle=90, vjust=0.05))
dev.off()