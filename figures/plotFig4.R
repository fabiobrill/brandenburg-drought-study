library(ggplot2)
library(viridis)

data = read.csv("./data/processed/all_indicators_on_exposure.csv")

head(data)

data$Year = factor(data$year)

x11()
jpeg("fig4.jpg", height = 500, width = 700)
ggplot(data) + geom_density(aes(LSTNDVI_anom, col=Year, fill=Year), adjust=2, size=rel(1.2), alpha=0.1) +
theme_bw(base_size = 25) +scale_color_viridis_d(option="plasma") +
scale_fill_viridis_d(option="plasma") +
xlim(-0.5,1.5)
dev.off()
