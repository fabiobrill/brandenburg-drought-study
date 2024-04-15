# Interactive data visualization tool for agricultural drought in Brandenburg, 2013-2022
# Details on the datasets and processing in the related publication
# App developed by Fabio Brill, 2024, during the project "Climate and Water under Change (CliWaC)"
# funded by the Einstein Foundation and Berlin University Alliance
# Contact: fabio.brill@hu-berlin.de

# ----------------------------------------------------------------------------------------------- #
# Dependencies
# ----------------------------------------------------------------------------------------------- #
library(bslib)
library(dplyr)
library(DT)
library(leaflet)
library(leafgl)
library(leafsync)
library(sf)
library(shiny)
library(shinyjs)
library(terra)
library(tidyr)

# ----------------------------------------------------------------------------------------------- #
# I/O
# ----------------------------------------------------------------------------------------------- #
setwd("./app/appdata/")

# outline of the country
brandenburg = read_sf("brandenburg_3857.gpkg")

# hazard
spei_march = rast("spei_stack_march.tif")
spei_april = rast("spei_stack_april.tif")
spei_may = rast("spei_stack_may.tif")
spei_june = rast("spei_stack_june.tif")
spei_july = rast("spei_stack_july.tif")
spei_magnitude = rast("SPEI_stack_magnitude.tif")
smi_march = rast("smi_stack_march.tif")
smi_april = rast("smi_stack_april.tif")
smi_may = rast("smi_stack_may.tif")
smi_june = rast("smi_stack_june.tif")
smi_july = rast("smi_stack_july.tif")
smi_magnitude = rast("smi_stack_magnitude.tif")
smi_total = rast("smi_stack_total.tif")

# exposure
exposure_table = read.csv("area_per_year_reported.csv")
lks = unique(exposure_table$NUTS_NAME) # names of the landkreise (i.e. counties) for selection

# vulnerability
azl = rast("azl_downsampled.tif")
twi = rast("twi_downsampled.tif")
nfk = rast("nfk_cropped.tif")
vulnerability = sf::read_sf("vi_4326.geojson")

# impacts
lstndvi = read_sf("lstndvi_anom_polygons.gpkg")
loss_estimate = read_sf("aloss4326.gpkg")
loss_long = read_sf("aloss_longformat.gpkg")

# crop model
pp_wheat = rast("cropmodel_pp_wheat.tif")
pp_rye = rast("cropmodel_pp_rye.tif")
pp_maize = rast("cropmodel_pp_maize.tif")
pp_barley = rast("cropmodel_pp_barley.tif")
wlp_wheat = rast("cropmodel_wlp_wheat.tif")
wlp_rye = rast("cropmodel_wlp_rye.tif")
wlp_maize = rast("cropmodel_wlp_maize.tif")
wlp_barley = rast("cropmodel_wlp_barley.tif")

# ----------------------------------------------------------------------------------------------- #
# Styling
# ----------------------------------------------------------------------------------------------- #
# background tiles and position of plot legends for all maps
basemap = providers$CartoDB.Positron
lpos = "bottomleft"

# value ranges for the color bars
rangeFreq = 0:10
rangeSMI = seq(0, 0.45, by=0.05)
rangeSMItotal = seq(0, 45, by=5)
rangeSPEI = seq(-2.5, 2.5, by=0.5)
rangeSPEImagn = seq(-6, -1, by=1)
rangeAZL = 1:90
rangeTWI = 5:30
rangeNFK = 30:300
rangeLSTNDVI = seq(-0.5, 0.5, by=0.1)
rangeCM = seq(0, 18000, by=1000)

# discretization of loss esimate for simple visualization
loss_long$colmapping = case_when(
  loss_long$aloss < 0 ~ "#004bcd",
  loss_long$aloss < 100 ~ "#ffffff",
  loss_long$aloss < 200 ~ "#ffd815",
  loss_long$aloss >= 200 ~ "#c42902"
)

# color palettes
nacol = "transparent"
freqpal = colorNumeric(c("transparent", "#ffd815", "#c42902"), rangeFreq, nacol)
speipal1 = colorNumeric(c("#c42902", "#ffd815", "transparent"), rangeSPEImagn, nacol)
speipal2 = colorNumeric(c("#c42902", "#ffd815", "#ffffff", "#004bcd"), rangeSPEI, nacol)
smipal1 = colorNumeric(c("transparent", "#ffd815", "#c42902"), rangeSMItotal, nacol)
smipal2 = colorNumeric(c("transparent", "#ffd815", "#c42902"), rangeSMI, nacol)
azlpal = colorNumeric(c("#c42902", "#ffd815", "#004bcd", "#002565"), rangeAZL, nacol)
twipal = colorNumeric(c("#c42902", "#ffd815", "#004bcd", "#002565"), rangeTWI, nacol)
nfkpal = colorNumeric(c("#c42902", "#ffd815", "#004bcd", "#002565"), rangeNFK, nacol)
cropmodelpal = colorNumeric(c("#c42902", "#ffd815", "#ffffff", "#004bcd"), rangeCM, nacol)

# ----------------------------------------------------------------------------------------------- #
# UI
# ----------------------------------------------------------------------------------------------- #
ui = fluidPage(
  theme = bslib::bs_theme(bootswatch = "sandstone"),

  # adjustments to text formatting
  tags$head(
    tags$style(
        HTML(
            ".title-panel {
                display: flex;
                justify-content: flex-start;
                align-items: flex-end;
                padding: 16px;
            }",
            ".title-panel h1 {
                font-size: 16pt;
                margin: 0;
                margin-right: 12px;
                line-height: 1.2;
            }",
            ".title-panel a {
                font-size: 12pt;
                margin: 0;
            }",
            ".selectize-input, .selectize-dropdown, .optgroup-header, .data-group, label {
                font-size: 80%;
            }",
        )
    )
  ),

  title = "Drought hazard, vulnerability, and impacts for agriculture in Brandenburg",
  tags$header(
      class = "col-sm-12 title-panel",
      tags$h1("Drought hazard, vulnerability, and impacts for agriculture in Brandenburg"),
      tags$a(
        href = "https://nhess.copernicus.org/",
        "for details please see the article submitted to NHESS")
  ),

  # Selection menu, sliders and buttons
  sidebarLayout(
    sidebarPanel(style = "height: 100vh",
      # Selection panel for interactive view of hazard data
      conditionalPanel(
        condition = "input.tabselector == 'Hazard'",
        selectInput("speimode", "Raw or Frequency", c("raw", "frequency"), selected="frequency"),
        selectInput("speimonth", "SPEI Month", c(
          "march", "april", "may", "june", "july", "magnitude"), selected="magnitude"),
        selectInput("smimonth", "SMI Month", c(
          "march", "april", "may", "june", "july", "magnitude", "total"), selected="total"),
        sliderInput('speiyear', 'Year (raw)', 2013, 2022, 2022, sep=""),
        sliderInput('speith', 'SPEI Threshold (frequency)', -2.5, -0.5, -0.5, step=0.5),
        sliderInput('smith', 'SMI Threshold (frequency)', 0, 0.45, 0, step=0.05)
      ),
      # Switch to display the exposure table as absolute hectare or percent change
      conditionalPanel(
        condition = "input.tabselector == 'Exposure'",
        selectInput('lk', 'Landkreis', lks, selected="Brandenburg"),
        selectInput('expmode', "Absolute [ha] | Change [%]", c("Absolute", "Change"))
      ),
      # Complex panel for interactive weighting of the vulnerability indicators
      conditionalPanel(
        condition = "input.tabselector == 'Vulnerability'",
        radioButtons("vlayer", "Vulnerability Indicator",
          c("'Ackerzahl' soil quality (high res.)" = "azl",
            "Topographic wetness index (high res.)" = "twi",
            "Plant-available water (nFK) (high res.)" = "nfk",
            "Agr. population density (2021)" = "s1",
            "Agr. dependency for livelihood (2020)" = "s2",
            "Education (2021)" = "s3",
            "GDP per capita (2022)" = "s4",
            "Poverty (2019)" = "s6",
            "Secured succession (2020)" = "s7",
            "Social dependency (2021)" = "s8",
            "Unemployment (2022)" = "s9",
            "Disadvantaged area (2022)" = "e2",
            "Farmland ratio (2020)" = "e3",
            "Forest ratio (2020)" = "e4",
            "Livestock health (2020)" = "e5",
            "Protected areas (2020)" = "e6",
            "Soil depth (2015)" = "e7",
            "Soil water erosion (2014)" = "e10",
            "Soil wind erosion (2014)" = "e11",
            "Water exchange frequency (2015)" = "e12",
            "Participation in local elections (2019)" = "c1",
            "Investments in risk reduction (2022)" = "a1"),
            selected="azl")
      ),
      # Slider to select the year for the crop model and empirical impact indicators
      conditionalPanel(
        condition = "input.tabselector == 'Impacts' || input.tabselector == 'Crop Model'",
        sliderInput('yr', 'Year', 2013, 2022, 2022, sep="")
      ),
      # Slider to select the crop model simulation
      conditionalPanel(
        condition = "input.tabselector == 'Crop Model'",
        selectInput("croptype", "Crop Type", c("wheat", "rye", "maize", "barley"))
      ),
      conditionalPanel(
        condition = "input.tabselector == 'Impacts'",
        tags$div("(takes a few seconds to load)")
      )
    ),
    # Arrangement of displayed outputs
    mainPanel(
      tabsetPanel(
        id = "tabselector", type = "tabs",
        tabPanel("Hazard", uiOutput("hazard"), htmlOutput("description1")),
        tabPanel("Exposure", div(DT::dataTableOutput(outputId = "exposure"),
          style = "font-size:50%"), htmlOutput("description2")),
        tabPanel("Vulnerability", leafletOutput("vulnerability"), htmlOutput("description3")),
        tabPanel("Crop Model", uiOutput("cropmodel"), htmlOutput("description4")),
        tabPanel("Impacts", uiOutput("impacts"), htmlOutput("description5"))
      )
    ) # main panel
  ) # sidebar
) # page

# ----------------------------------------------------------------------------------------------- #
# Server
# ----------------------------------------------------------------------------------------------- #
server = function(input, output){
  # Hazard indicators SPEI-Magnitude and SMI-Total as synced maps
  output$hazard = renderUI({
    # Raw values of the SPEI and SMI layers
    if(input$speimode == "raw"){
      speilayer = get(paste0("spei_", input$speimonth))
      smilayer = get(paste0("smi_", input$smimonth))
      if(input$speimonth == "magnitude"){speipal= speipal1; vrangeSPEI=rangeSPEImagn
      } else {speipal =  speipal2; vrangeSPEI=rangeSPEI}
      if(input$smimonth == "total"){vrangeSMI=rangeSMItotal; smipal=smipal1
      } else {vrangeSMI=rangeSMI; smipal=smipal2}
      # create the two maps and store them in separate variables
      m1 = leaflet() %>% addProviderTiles(basemap) %>%
          addRasterImage(speilayer[[(input$speiyear-2012)]], colors = speipal, opacity = 0.8) %>%
          addLegend(pal = speipal, values = vrangeSPEI, title = "SPEI", position = lpos)
      m2 = leaflet() %>% addProviderTiles(basemap) %>%
          addRasterImage(smilayer[[(input$speiyear-2012)]], colors = smipal, opacity = 0.8) %>%
          addLegend(pal = smipal, values = vrangeSMI, title = "SMI",  position = lpos)
    # Drought frequency as number of peaks > | < selected thresholds
    } else if(input$speimode == "frequency"){
      speilayer = get(paste0("spei_", input$speimonth))
      smilayer = get(paste0("smi_", input$smimonth))
      if(input$smimonth == "total"){smilayer = smilayer/100} # for using the same slider
      spei_below_threshold = sum(speilayer < input$speith)
      smi_over_threshold = sum(smilayer > input$smith)
      m1 = leaflet() %>% addProviderTiles(basemap) %>%
          addRasterImage(spei_below_threshold, colors = freqpal, opacity = 0.8) %>%
          addLegend(pal = freqpal, values = rangeFreq, title = "#SPEI < Th.", position = lpos)
      m2 = leaflet() %>% addProviderTiles(basemap) %>%
          addRasterImage(smi_over_threshold, colors = freqpal, opacity = 0.8) %>%
          addLegend(pal = freqpal, values = rangeFreq, title = "#SMI > Th.", position = lpos)
    }
    # align both maps alongside each other
    sync(m1, m2)
  })

  # Exposure table
  output$exposure = DT::renderDataTable({
    if(input$expmode == "Absolute"){
      exposure_table %>% dplyr::filter(NUTS_NAME == input$lk) %>% dplyr::select(-X)
    } else if(input$expmode == "Change"){
      t1 = exposure_table %>% dplyr::filter(NUTS_NAME == input$lk) %>% dplyr::select(-X, -NUTS_NAME)
      t2 = t1[2:nrow(t1),]
      t3 = t2 - t1[1:(nrow(t1)-1),]
      t4 = round((t3[,-1] / t1[1:(nrow(t1)-1),-1])*100, 0) %>% lapply(as.integer) %>% as.data.frame()
      years = t1$year
      year_dif = paste(years[-1], "to", years[1:(length(years)-1)])
      dfout = cbind.data.frame(year_dif, t4)
      decadal_change = round((((t1 %>% dplyr::filter(year==2022)) - 
                               (t1 %>% dplyr::filter(year==2013))) / 
                               (t1 %>% dplyr::filter(year==2013)))*100, 0) %>% 
                       dplyr::select(-year)
      dfout = rbind.data.frame(dfout, cbind(year_dif = "2022 to 2013", decadal_change))
      dfout = DT::datatable(dfout)
      return(dfout %>% formatStyle(columns=colnames(t4), color=styleInterval(0, c("red","green"))))
    }
  })

  output$vulnerability = renderLeaflet({
    if(input$vlayer %in% c("azl", "twi", "nfk")){
      vraster = get(input$vlayer)
      vals = values(vraster)
      vrasterpal = get(paste0(input$vlayer, "pal"))
      leaflet() %>% addProviderTiles(basemap) %>%
        addRasterImage(vraster, colors = vrasterpal, opacity = 0.8) %>%
        addLegend(pal = vrasterpal, values = vals, title = input$vlayer, position=lpos)
    } else {
      temp = vulnerability[[input$vlayer]]
      quantiles = quantile(temp)
      quantilecolor = case_when(
        temp < quantiles["25%"] ~ "#004bcd",
        temp < quantiles["50%"] ~ "#ffffff",
        temp < quantiles["75%"] ~ "#ffd815",
        temp >= quantiles["75%"] ~ "#c42902",
        is.na(temp) ~ "transparent"
      )
      leaflet() %>%
        addProviderTiles(basemap) %>%
        addPolygons(data = vulnerability[input$vlayer], color = "#444444", weight = 1,
          smoothFactor = 0.5, opacity = 1.0, fillOpacity = 0.5, fillColor = quantilecolor,
          highlightOptions = highlightOptions(color = "white", weight = 2, bringToFront = T)) %>%
        addLegend(labels=c("Q1", "Q2", "Q3", "Q4"),
                  colors=c("#004bcd", "#ffffff", "#ffd815", "#c42902"),
                  title = input$vlayer,  position = lpos)
    }
  })

  # Impacts on field level (LST/NDVI-Anom.) AND on county level (EUR/ha) as synced maps
  output$impacts = renderUI({
      labelText = sprintf("<strong>%s</strong><br/>%s €.ha<sup> -1</sup>",
        loss_estimate$NUTS_NAME, round(loss_estimate[[paste0("aloss", input$yr)]], 1)) %>%
        lapply(htmltools::HTML)
      subdata = lstndvi %>% 
        dplyr::filter(year == input$yr) #%>%
        #st_cast(to="POLYGON")
      polygoncolor = case_when(
        subdata$LSTNDVI_anom < 0 ~ "#004bcd",
        subdata$LSTNDVI_anom < 0.1 ~ "#ffffff",
        subdata$LSTNDVI_anom < 0.25 ~ "#ffd815",
        subdata$LSTNDVI_anom >= 0.25 ~ "#c42902",
        is.na(subdata$LSTNDVI_anom) ~ "transparent"
      )
      m1 = leaflet() %>% addProviderTiles(basemap) %>%
        addGlPolygons(data = subdata, fillColor= polygoncolor, popup = NULL) %>%
        addLegend(labels=c("< 0", "< 0.1", "< 0.25", "> 0.25"),
          colors=c("#004bcd", "#ffffff", "#ffd815", "#c42902"),
          title = "LST/NDVI-Anom.",  position = lpos)
      subloss = loss_long %>% dplyr::filter(year==input$yr)
      m2 = leaflet(subloss) %>% 
        addProviderTiles(basemap) %>%
        addPolygons(layerId = subloss$NUTS_NAME, color = "#444444", weight = 1,
          smoothFactor = 0.5, opacity = 1.0, fillOpacity = 0.5,
          fillColor = subloss$colmapping,
          highlightOptions = highlightOptions(color = "white", weight = 2, bringToFront = T),
          label = lapply(labelText, htmltools::HTML)) %>%
        addLegend(labels=c("< 0", "0 - 100", "100 - 200", "> 200"),
          colors=c("#004bcd", "#ffffff", "#ffd815", "#c42902"),
          title = "Loss estimate [€/ha]",  position = lpos)
      sync(m1, m2)
  })

  # Crop model visualization
  output$cropmodel = renderUI({
    pp_raster = get(paste0("pp_", input$croptype))
    wlp_raster = get(paste0("wlp_", input$croptype))
    pp_vals = values(pp_raster[[input$yr - 2012]])
    wlp_vals = values(wlp_raster[[input$yr - 2012]])
    m1 = leaflet() %>% addProviderTiles(basemap) %>%
      addRasterImage(pp_raster[[input$yr - 2012]], colors = cropmodelpal, opacity = 0.8) %>%
      addLegend(pal = cropmodelpal, values = rangeCM, title = "PP", position=lpos)
    m2 = leaflet() %>% addProviderTiles(basemap) %>%
      addRasterImage(wlp_raster[[input$yr - 2012]], colors = cropmodelpal, opacity = 0.8) %>%
      addLegend(pal = cropmodelpal, values = rangeCM, title = "WLP", position=lpos)
    sync(m1, m2)
  })

  # short texts to display at each tab below the figures
  output$description1 = renderUI({
    HTML(
      "*Standardized Precipitation-Evaporation Index (SPEI) provided by Huihui Zhang 
      [https://doi.org/10.3390/rs16050828] and Soil Moisture Index (SMI) provided by 
      Friedrich Boeing [https://doi.org/10.5194/hess-26-5137-2022]. SPEI-Magnitude refers to the 
      sum of monthly SPEI, March-July, where SPEI < -0.5. Note that the value range of 
      SPEI-Magnitude is consequently lower than the value range of the monthly layers.
      SMI-Total refers to the drought magnitude in the total soil (1.8 m) aggregated from 
      April to October, while all other SMI layers refer to the intensity in the top soil (25 cm).
      'Frequency' returns the count of years where the selected indicator is above/below the 
      selected threshold. Values of SMI-Total are internally divided by 100 to match the value
      range of the monthly SMI layers (to use the same slider for all layers).
      For details on the methodology, please see the journal article: [link]"
    )
  })

  output$description2 = renderUI({
    HTML(
      "*data from the regional statistical authorities
      [https://www.statistik-berlin-brandenburg.de/c-ii-2-j],
      compiled by Pedro Alencar [https://github.com/pedroalencar1/CropYield_BBr]"
    )
  })
  
  output$description3 = renderUI({
    HTML(
      "*data sources and descriptions see Table 1 in the journal article (link above).
      Aggregated indicators on county level are displayed in quantiles, where
      Q1 refers to the lowest 25% and Q4 to the highest 25% of the values.
      Selection based on Laudien (2023): 
      'Agricultural drought vulnerability in Brandenburg - A composite index assessment',
      Master's thesis at Humboldt-Universtität zu Berlin."
    )
  })

  output$description4 = renderUI({
    HTML(
      "*Potential production (PP) and water-limited production (WLP) for 4 selected crop types.
      Simulation conducted by Pedro Alencar [https://orcid.org/0000-0001-6221-8580]
      using the WOFOST model [https://doi.org/10.1016/j.agsy.2018.06.018] 
      and CER climatic forcing [https://doi.org/10.1002/joc.4835]."
    )
  })

  output$description5 = renderUI({
    HTML(
      "*Two different impact indicators: (1) the ratio of land surface temperature (LST) and
      normalized difference vegetation index (NDVI) from Landsat-8 imagery on the level of 
      individual fields. (2) Estimated loss per hectare on county level based on the difference 
      of expected and reported yields for 12 selected crop types. Values are point estimates 
      without quantification of uncertainty. For details on the methodology, please see the +
      journal article (link above)"
    )
  })
} # server

# ----------------------------------------------------------------------------------------------- #
# Run App
# ----------------------------------------------------------------------------------------------- #
shinyApp(ui = ui, server = server)