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
                                  axis.title=element_text(size=14,face="bold"))
}

x11()
jpeg("../../figures/fig3.jpg", width=1500, height=300)
plot_grid(plot_grid(plotlist[["wheat"]],
                    plotlist[["rye"]],
                    plotlist[["barley"]],
                    plotlist[["maize"]],
                    nrow=1,
                    labels="AUTO"),
          plot_grid(sharedLegend), 
          rel_widths = c(0.85, 0.15)
          )
dev.off()

jpeg("../../figures/fig3.jpg", width=1450, height=400)
plot_grid(plot_grid(plotlist[["wheat"]],
                    plotlist[["rye"]],
                    plotlist[["barley"]],
                    plotlist[["maize"]],
                    nrow=1,
                    labels="AUTO"),
          plot_grid(sharedLegend),
          nrow=2,
          rel_heights = c(0.85, 0.15)
          )
dev.off()


#ggplot(df) +geom_point(aes(modelled_wlp, SPEI_jun)) +theme_bw()
#ggplot(df) +geom_point(aes(modelled_wlp, LSTNDVI_anom, col=factor(lbg)), size=0.01) +geom_smooth(aes(modelled_wlp, LSTNDVI_anom, col=factor(lbg))) +theme_bw()
#ggplot(df) +geom_point(aes(1-(modelled_wlp/modelled_pp), LSTNDVI_anom), size=0.01) +geom_smooth(aes(1-(modelled_wlp/modelled_pp), LSTNDVI_anom, col=factor(lbg)), method="lm") +theme_bw()
#ggplot(df) +geom_point(aes(modelled_wlp, azl, col=factor(lbg)), size=0.01) +geom_smooth(aes(modelled_wlp, azl)) +theme_bw()#

#ggplot(df) +geom_smooth(aes(modelled_wlp, LSTNDVI)) +theme_bw()
#ggplot(df) +geom_smooth(aes(modelled_wlp, LSTNDVI_anom)) +theme_bw()
#ggplot(df) +geom_smooth(aes(modelled_wlp, azl)) +theme_bw()

