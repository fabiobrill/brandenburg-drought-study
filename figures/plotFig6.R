library(dplyr)
library(ggplot2)

df = read.csv("./data/processed/all_indicators_on_exposure.csv")
df = df %>% group_by(year, crop) %>% summarise(area_iacs = sum(area_iacs)) %>% ungroup()
total_area = df %>% group_by(year) %>% summarize(cropped_area = sum(area_iacs))
merged = merge(df, total_area)
merged$area_frac = merged$area_iacs / merged$cropped_area

croplabels = c(grain_maize = "Grain Maize",
               lupines = "Lupines",
               oat = "Oat",
               peas = "Peas",
               potatoes = "Potatoes",
               rye = "Rye",
               sugarbeet = "Sugar Beet",
               sunflower = "Sunflower",
               triticale = "Triticale",
               winter_barley = "Winter Barley",
               winter_canola = "Winter Canola",
               winter_wheat = "Winter Wheat")

colmapping = c("grain_maize" = "dodgerblue2",
               "lupines" = "#E31A1C",
               "oat" = "green4",
               "peas" = "#6A3D9A",
               "potatoes" = "#FF7F00",
               "rye" = "palegreen2",
               "sugarbeet" = "skyblue2",
               "sunflower" = "#FB9A99",
               "triticale" = "khaki2",
               "winter_barley" = "maroon",
               "winter_canola" = "steelblue4",
               "winter_wheat" = "gold1")

x11()

jpeg("./figures/fig6bar.jpg", width = 800,height = 500, quality=100, type="cairo", antialias="subpixel")
ggplot(merged) +geom_col(aes(year, area_iacs/1000, fill=crop))+
scale_fill_manual(values=colmapping, labels=croplabels) +
theme_bw(base_size = 20) +xlab("") +scale_x_continuous(breaks=2013:2022, labels=2013:2022) +
theme(legend.position = "bottom", legend.title = element_blank()) +
ylab("Cropped area [10³ ha]")
dev.off()