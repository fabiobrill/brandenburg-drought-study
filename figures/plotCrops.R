library(dplyr)
library(ggplot2)

setwd("./data/processed")
df = read.csv("all_indicators_on_exposure.csv")

#df = read.csv("D:/gitscripts/teaching/teaching/cropdf.csv")

df = df %>% group_by(year, crop) %>% summarise(area_iacs = sum(area_iacs)) %>% ungroup()
df

x11()
ggplot(df) +geom_line(aes(year, area_iacs, col=crop), size=1) +
theme_bw() +ylab("Anbaufläche [ha]") +xlab("Jahr") +scale_x_continuous(breaks=2013:2022, labels=2013:2022)

head(df)

total_area = df %>% group_by(year) %>% summarize(cropped_area = sum(area_iacs))

total_area

merged = merge(df, total_area)
head(merged)

merged$area_frac = merged$area_iacs / merged$cropped_area


x11()
jpeg("figCrops.jpg", width = 800,height = 500, quality=100, type="cairo", antialias="subpixel")
ggplot(merged) +geom_line(aes(year, area_frac, col=crop), size=1) +
geom_line(aes(year, cropped_area/5000000), size=1, data=total_area, linetype="dashed") +
theme_bw(base_size = 20) +ylab("Fraction per crop type") +xlab("") +scale_x_continuous(breaks=2013:2022, labels=2013:2022) +
scale_y_continuous(sec.axis = sec_axis(~.*5000000, name="Total cropped area [ha]")) +
theme(legend.position = "bottom")
dev.off()