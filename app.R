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
library(ggplot2)
library(leaflet)
library(leafgl)
library(leafsync)
library(plotly)
library(sf)
library(shiny)
library(shinyjs)
library(terra)
library(tidyr)

# ----------------------------------------------------------------------------------------------- #
# I/O
# ----------------------------------------------------------------------------------------------- #
setwd("./data/appdata/")

brandenburg = read_sf("Brandenburg.shp")["NAME_0"] %>% st_transform(3857)

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

# vulnerability
azl = rast("ackerzahl_nonzero_30m.tif") #%>% project("EPSG:3857") %>% crop(brandenburg) %>% mask(brandenburg)
twi = rast("twi.tif") #%>% project("EPSG:3857") %>% crop(brandenburg) %>% mask(brandenburg)
nfk = rast("nfk.tif") %>% project("EPSG:3857") %>% crop(brandenburg) %>% mask(brandenburg)
vulnerability = sf::read_sf("vi_4326.geojson")
vdata = dplyr::select(as.data.frame(vulnerability), -geometry)

# impacts # rename to indicators or simply use lstndvi? how about azl, twi, ...?
indicators = sf::read_sf("../processed/all_indicators_on_exposure.gpkg") %>% 
             dplyr::select(year, crop, LSTNDVI_anom, SPEI_magnitude, SMI_total)
#lstndvi = indicators %>% select(LSTNDVI_anom) #?
loss_estimate = read_sf("aloss.gpkg") %>% st_transform(4326)
library(tidyr)
loss_long = pivot_longer(loss_estimate, cols=3:(ncol(loss_estimate)-1), 
                         names_to="year", values_to="aloss", names_prefix="aloss")
#impacts = sf::read_sf("aloss.gpkg") %>% sf::st_transform(4326)
#impacts = sf::read_sf("loss_4326.gpkg")
#gaps = read.csv("gap_table.csv") %>% select(-X) # needed at all?

# crop model
pp_wheat = rast("descriptive/cropmodel/cropmodel_pp_wheat.tif")
pp_rye = rast("descriptive/cropmodel/cropmodel_pp_rye.tif")
pp_maize = rast("descriptive/cropmodel/cropmodel_pp_maize.tif")
pp_barley = rast("descriptive/cropmodel/cropmodel_pp_barley.tif")
wlp_wheat = rast("descriptive/cropmodel/cropmodel_wlp_wheat.tif")
wlp_rye = rast("descriptive/cropmodel/cropmodel_wlp_rye.tif")
wlp_maize = rast("descriptive/cropmodel/cropmodel_wlp_maize.tif")
wlp_barley = rast("descriptive/cropmodel/cropmodel_wlp_barley.tif")

# is this needed anywhere?
lks = unique(exposure_table$NUTS_NAME) # names of the landkreise
impacted_lstndvi = read.csv("impactarea_thresholds_lstndvi.csv")
impacted_spei = read.csv("impactarea_threshold_spei_monthly.csv")

# ----------------------------------------------------------------------------------------------- #
# Styling
# ----------------------------------------------------------------------------------------------- #
rangeSMI = seq(0, 0.45, by=0.05)
rangeSMItotal = seq(0, 45, by=5)
rangeSPEI = seq(-2.5, 2.5, by=0.5)
rangeSPEImagn = seq(-6, -1, by=1)
rangeLSTNDVI = seq(-0.5, 0.5, by=0.1)
rangeCropModel = seq(0, 18000, by=1000)

nacol = "transparent"
pal1 = colorNumeric(c("#c42902", "#ffd815", "transparent"), rangeSPEImagn, na.color = nacol)
pal2 = colorNumeric(c("#c42902", "#ffd815", "#ffffff","#004bcd"), rangeSPEI, na.color = nacol)
pal3 = colorNumeric(c("transparent", "#ffd815", "#c42902"), rangeSMI, na.color = nacol)
pal4 = colorNumeric(c("transparent", "#ffd815", "#c42902"), rangeSMI, na.color = nacol)
pal5 = colorNumeric(c("transparent", "#ffd815", "#c42902"), rangeSMItotal, na.color = nacol)
trendpal = colorNumeric(c("transparent", "#34ff1500", "#ffd500"), 0:1, na.color = nacol)
peakpal = colorNumeric(c("transparent", "#ffd815", "#c42902"), 0:10, na.color = nacol)
cropmodelpal = colorNumeric(c("#c42902", "#ffd815", "#ffffff","#004bcd"), rangeCropModel, na.color = nacol)

#polygoncolor = colorNumeric(c("#004bcd", "#ffffff", "#ffd815", "#c42902"), rangeLSTNDVI, na.color = nacol)

loss_long$colmapping = case_when(
  loss_long$aloss < 0 ~ "#004bcd",
  loss_long$aloss < 100 ~ "#ffffff",
  loss_long$aloss < 200 ~ "#ffd815",
  loss_long$aloss >= 200 ~ "#c42902"
)

lpos = "bottomleft"

# ----------------------------------------------------------------------------------------------- #
# UI
# ----------------------------------------------------------------------------------------------- #
ui = fluidPage(
  theme = bslib::bs_theme(bootswatch = "sandstone"),
  #titlePanel("Drought hazard, vulnerability, and impacts for agriculture in Brandenburg"),

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
      # Slider (1) to select the year
      conditionalPanel(
      condition = "input.tabselector == 'Impacts' || input.tabselector == 'Crop Model'",
      sliderInput('yr', 'Year', 2013, 2022, 2013, sep="")
    ),
      # Slider (2) to select the year of crop model simulation - should be merged with (1)?
      conditionalPanel(
      condition = "input.tabselector == 'Crop Model'",
      #sliderInput('modelyear', 'Model Year', 1, 30, 1, sep=""),
      selectInput("croptype", "Crop Type", c("wheat", "rye", "maize", "barley"))
    ),
      # Selection panel for interactive view of hazard data
      conditionalPanel(
      condition = "input.tabselector == 'Hazard'",
      selectInput("speimode", "Raw or Frequency", c("raw", "frequency")),
      selectInput("speimonth", "SPEI Month", c("march", "april", "may", "june", "july",
                                               "magnitude"), selected="magnitude"),
      selectInput("smimonth", "SMI Month", c("march", "april", "may", "june", "july",
                                             "magnitude", "total"), selected="total"),
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
      # - probably should be removed?
      conditionalPanel(
      condition = "input.tabselector == 'Vulnerability'",
      radioButtons("vlayer", "Vulnerability Indicator",
        c("AZL (high res.)" = "azl",
          "TWI (high res.)" = "twi",
          "NFK (high res.)" = "nfk",
          "Agr. population density (2021)" = "s1",
          "Agr. dependency for livelihood (2021)" = "s2",
          "Education" = "s3",
          "GDP per capita" = "s4",
          "GPD per farmer" = "s5",
          "Poverty" = "s6",
          "Secured succession" = "s7",
          "Social dependency" = "s8",
          "Unemployment" = "s9",
          "Field capacity" = "e1",
          "Disadvantaged area" = "e2",
          "Farmland ratio" = "e3",
          "Forest ratio" = "e4",
          "Livestock health" = "e5",
          "Protected areas" = "e6",
          "Soil depth" = "e7",
          "Soil estimation" = "e8",
          "Soil quality rating" = "e9",
          "Soil water erosion" = "e10",
          "Soil wind erosion" = "e11",
          "Water exchange frequency" = "e12",
          "Topographic wetness index" = "e13",
          "Public participation in local policy" = "c1",
          "Investment in disaster prevention and preparedness" = "c2"),
          selected="azl")
    ),
      conditionalPanel(condition = "input.tabselector == 'Impacts'",
                    tags$div("(takes a few seconds to load)")
    )
  ),
  # Arrangement of displayed outputs
  mainPanel(
    tabsetPanel(
      id = "tabselector", type = "tabs",
      tabPanel("Hazard", uiOutput("hazard"), htmlOutput("description1")),
      tabPanel("Exposure", div(DT::dataTableOutput(outputId = "exposure"), style = "font-size:50%"), htmlOutput("description2")),
      tabPanel("Vulnerability", leafletOutput("vulnerability"), htmlOutput("description3")),
      tabPanel("Crop Model", uiOutput("cropmodel"), htmlOutput("description4")),
      tabPanel("Impacts", uiOutput("impacts"), htmlOutput("description5"))#, plotlyOutput("timeplot", height="30vh"))
    )
  )
) # sidebar
) # page

# ----------------------------------------------------------------------------------------------- #
# Server
# ----------------------------------------------------------------------------------------------- #
server = function(input, output){
  # init reactive values and observer for click events
  #rv_location = reactiveValues(id=NULL,lat=NULL,lng=NULL)
  #rv_shape = reactiveVal(FALSE)
  #observe(shinyjs::toggle(id = "tabselector", condition = ifelse(input$tabs == 'Impacts', TRUE, FALSE)))

  # Hazard indicators SPEI-Magnitude and SMI-Total as synced maps
  output$hazard = renderUI({
    # Raw values of the SPEI and SMI layers
    if(input$speimode == "raw"){
      speilayer = get(paste0("spei_", input$speimonth))
      smilayer = get(paste0("smi_", input$smimonth))
      if(input$speimonth == "magnitude"){speipal= pal1; vrangeSPEI=rangeSPEImagn} else {speipal =  pal2; vrangeSPEI=rangeSPEI}
      if(input$smimonth == "total"){vrangeSMI=rangeSMItotal; smipal=pal5} else {vrangeSMI=rangeSMI; smipal=pal3} #smilayer = smilayer/100; 
      m1 = leaflet() %>% addProviderTiles(providers$CartoDB.Positron) %>%
          addRasterImage(speilayer[[(input$speiyear-2012)]], colors = speipal, opacity = 0.8) %>%
          addLegend(pal = speipal, values = vrangeSPEI, title = "SPEI", position = lpos)
      m2 = leaflet() %>% addProviderTiles(providers$CartoDB.Positron) %>%
          addRasterImage(smilayer[[(input$speiyear-2012)]], colors = smipal, opacity = 0.8) %>%
          addLegend(pal = smipal, values = vrangeSMI, title = "SMI",  position = lpos)
      # Drought frequency as number of peaks > | < selected thresholds
      } else if(input$speimode == "frequency"){
      speilayer = get(paste0("spei_", input$speimonth))
      smilayer = get(paste0("smi_", input$smimonth))
      if(input$smimonth == "total"){smilayer = smilayer/100}
      spei_below_threshold = sum(speilayer < input$speith)
      smi_over_threshold = sum(smilayer > input$smith)
      pal = peakpal
      m1 = leaflet() %>% addProviderTiles(providers$CartoDB.Positron) %>%
          addRasterImage(spei_below_threshold, colors = pal, opacity = 0.8) %>%
          addLegend(pal = pal, values = 0:10, title = "#SPEI < Th.", position = lpos)
      m2 = leaflet() %>% addProviderTiles(providers$CartoDB.Positron) %>%
          addRasterImage(smi_over_threshold, colors = pal, opacity = 0.8) %>%
          addLegend(pal = pal, values = 0:10, title = "#SMI > Th.", position = lpos)
      # add UFZ soil drought data in separate mapview
      #peak_over_threshold = sum(ufz > input$th)
      #vals = values(peak_over_threshold)
      #pal_ufz = colorNumeric(c("transparent", "#ffd815", "#d30000"), 0:7, na.color = "transparent")
    }
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
  })#, spacing='xs', striped=T)

  output$vulnerability = renderLeaflet({
    if(input$vlayer %in% c("azl", "twi", "nfk")){
      vraster = get(input$vlayer) %>% terra::aggregate(10)
      vals = values(vraster)
      vrasterpal = colorNumeric(c("#0C2C84", "#41B6C4", "#FFFFCC"), vals, na.color = nacol)
      leaflet() %>% addProviderTiles(providers$CartoDB.Positron) %>%
        addRasterImage(vraster, colors = vrasterpal, opacity = 0.8) %>%
        addLegend(pal = vrasterpal, values = vals, title = input$vlayer)
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
        addProviderTiles(providers$CartoDB.Positron) %>%
        addPolygons(data = vulnerability[input$vlayer], color = "#444444", weight = 1,
          smoothFactor = 0.5, opacity = 1.0, fillOpacity = 0.5, fillColor = quantilecolor,
          highlightOptions = highlightOptions(color = "white", weight = 2, bringToFront = TRUE)) %>%
        addLegend(labels=c("Q1", "Q2", "Q3", "Q4"),
                  colors=c("#004bcd", "#ffffff", "#ffd815", "#c42902"),
                  title = input$vlayer,  position = lpos)
    }
  })

  # Impacts on field level (LST/NDVI-Anom.) AND on county level (EUR/ha) as synced maps
  output$impacts = renderUI({
      labelText = sprintf("<strong>%s</strong><br/>%s €.ha<sup> -1</sup>",
                          loss_estimate$NUTS_NAME,
                          round(loss_estimate[[paste0("aloss", input$yr)]], 1)) %>% lapply(htmltools::HTML)
      
      subdata = indicators %>% dplyr::filter(year == input$yr) %>% dplyr::select(LSTNDVI_anom) %>% st_cast(to="POLYGON")
      polygoncolor = case_when(
        subdata$LSTNDVI_anom < 0 ~ "#004bcd",
        subdata$LSTNDVI_anom < 0.1 ~ "#ffffff",
        subdata$LSTNDVI_anom < 0.25 ~ "#ffd815",
        subdata$LSTNDVI_anom >= 0.25 ~ "#c42902",
        is.na(subdata$LSTNDVI_anom) ~ "transparent"
      )
      m1 = leaflet() %>% addProviderTiles(providers$CartoDB.Positron) %>%
           addGlPolygons(data = subdata, color= polygoncolor, popup = NULL, group = "pols") %>%
                         addLegend(labels=c("< 0", "< 0.1", "< 0.25", "> 0.25"),
                                   colors=c("#004bcd", "#ffffff", "#ffd815", "#c42902"),
                                   title = "LST/NDVI-Anom.",  position = lpos)
      subloss = loss_long %>% dplyr::filter(year==input$yr)
      m2 = leaflet(subloss) %>% 
             addProviderTiles(providers$CartoDB.Positron) %>%
             addPolygons(layerId = subloss$NUTS_NAME, color = "#444444", weight = 1, smoothFactor = 0.5, opacity = 1.0,
             fillOpacity = 0.5,
             fillColor = subloss$colmapping,
             highlightOptions = highlightOptions(color = "white", weight = 2, bringToFront = TRUE),
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
    m1 = leaflet() %>% addProviderTiles(providers$CartoDB.Positron) %>%
           addRasterImage(pp_raster[[input$yr - 2012]], colors = cropmodelpal, opacity = 0.8) %>%
           addLegend(pal = cropmodelpal, values = rangeCropModel, title = "PP", position=lpos)
    m2 = leaflet() %>% addProviderTiles(providers$CartoDB.Positron) %>%
           addRasterImage(wlp_raster[[input$yr - 2012]], colors = cropmodelpal, opacity = 0.8) %>%
           addLegend(pal = cropmodelpal, values = rangeCropModel, title = "WLP", position=lpos)
          sync(m1, m2)
  })

  # short texts to display at each tab below the figures
  output$description1 = renderUI({
    HTML("*Standardized Precipitation-Evaporation Index (SPEI) provided by Huihui Zhang [https://doi.org/10.3390/rs16050828]
          and Soil Moisture Index (SMI) provided by Friedrich Boeing [https://doi.org/10.5194/hess-26-5137-2022]. 
          SPEI-Magnitude refers to the sum of monthly SPEI, March-July, where SPEI < -0.5. Note that the value range of
          SPEI-Magnitude is consequently lower than the value range of the monthly layers.
          SMI-Total refers to the drought magnitude in the total soil (1.8 m) aggregated from April to October,
          while all other SMI layers refer to the intensity in the top soil (25 cm).
          'Frequency' returns the count of years where the selected indicator is above/below the selected threshold.
          Values of SMI-Total are internally divided by 100 to match the value range of the monthly SMI layers 
          (to use the same slider for all layers).
          For details on the methodology, please see the journal article: [link]")
  })

  output$description2 = renderUI({
    HTML("*data from the regional statistical authorities [https://www.statistik-berlin-brandenburg.de/c-ii-2-j],
         compiled by Pedro Alencar [https://github.com/pedroalencar1/CropYield_BBr]")
  })
  
  output$description3 = renderUI({
    HTML("*data by ... and ... for individual years")
  })

  output$description4 = renderUI({
    HTML("*Potential production (PP) and water-limited production (WLP) for 4 selected crop types.
          Simulation conducted by Pedro Alencar [https://orcid.org/0000-0001-6221-8580]
          using the WOFOST model [https://doi.org/10.1016/j.agsy.2018.06.018] 
          and CER climatic forcing [https://doi.org/10.1002/joc.4835].")
  })

  output$description5 = renderUI({
    HTML("*Two different impact indicators, based on RS and yield reports.
          Values are simple estimates without quantification of uncertainty.
          For details on the methodology, please see the journal article: [link]")
  })

}

# ----------------------------------------------------------------------------------------------- #
# Run App
# ----------------------------------------------------------------------------------------------- #
shinyApp(ui = ui, server = server)