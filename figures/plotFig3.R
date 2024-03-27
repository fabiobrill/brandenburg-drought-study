library(dplyr)
library(ggplot2)
library(cowplot)

setwd("./data/processed")


means_per_crop = read.csv("means_per_crop.csv")
plotlist = list()
for(coi in c("wheat", "rye", "barley", "maize")){
    df = read.csv(paste0("cropmodel_", coi, ".csv"))
    df$LBG = as.factor(df$LBG)
    df$NDVI = df$NDVI / 1000
    df$LSTNDVI = df$LST / df$NDVI
    df = df %>% na.omit
    anomalies = df %>% select(year, crop, LSTNDVI) %>% 
                    left_join(means_per_crop) %>% 
                    transmute(year = year,
                                crop = crop,
                                LSTNDVI_anom = ((LSTNDVI-LSTNDVI_wm)/LSTNDVI_wm))
    df$LSTNDVI_anom = anomalies$LSTNDVI_anom

    if(coi == "wheat"){
        tempplot = ggplot(df) +geom_point(aes(modelled_yield_pp, yield_expected, col=LBG), size=4) +
                               theme_bw(base_size = 20) +theme(legend.position="bottom")
        sharedLegend = cowplot::get_legend(tempplot)
    }

    plotlist[[coi]] = ggplot(df) +geom_point(aes(modelled_yield_pp, yield_expected, col=LBG),
                                             size=0.01, show.legend = F) +
                                  geom_abline() +theme_bw() +xlim(0,12000) +ylim(0,12000) +
                                  xlab("Modelled yield (PP)") +ylab("Expected yield") +
                                  theme(axis.text=element_text(size=13),
                                  axis.title=element_text(size=14,face="bold")) +
                                  theme(plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm"))
}

jpeg("../../figures/fig3.jpg", width=1450, height=400, quality=100, type="cairo", antialias="subpixel")
#png("../../figures/fig3.png", pointsize=0.01, res=400, width=17.7, height=4.8, units="cm", antialias = "cleartype")
plot_grid(plot_grid(plotlist[["wheat"]],
                    plotlist[["rye"]],
                    plotlist[["barley"]],
                    plotlist[["maize"]],
                    nrow=1,
                   labels=c("(a)", "(b)", "(c)", "(d)")),
          plot_grid(sharedLegend),
          nrow=2,
          rel_heights = c(0.85, 0.15)
          )
dev.off()