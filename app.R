# Interactive data visualization tool for agricultural drought in Brandenburg, 2013-2022
# Details on the datasets and processing in the related publication
# App written by Fabio Brill, 2024
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
vulnerability = sf::read_sf("vi_4326.geojson")
vdata = dplyr::select(as.data.frame(vulnerability), -geometry)

# impacts # rename to indicators or simply use lstndvi? how about azl, twi, ...?
indicators = sf::read_sf("../processed/all_indicators_on_exposure.gpkg") %>% 
             dplyr::select(year, crop, LSTNDVI_anom, SPEI_magnitude, SMI_total)
#lstndvi = indicators %>% select(LSTNDVI_anom) #?
impacts = sf::read_sf("aloss.gpkg") %>% sf::st_transform(4326)
#impacts = sf::read_sf("loss_4326.gpkg")
#gaps = read.csv("gap_table.csv") %>% select(-X) # needed at all?

# crop model
cropmodel_wheat = rast("descriptive/cropmodel/cropmodel_pp_wheat.tif")
cropmodel_rye = rast("descriptive/cropmodel/cropmodel_pp_rye.tif")
cropmodel_maize = rast("descriptive/cropmodel/cropmodel_pp_maize.tif")
cropmodel_barley = rast("descriptive/cropmodel/cropmodel_pp_barley.tif")

# is this needed anywhere?
lks = unique(exposure_table$NUTS_NAME) # names of the landkreise
impacted_lstndvi = read.csv("impactarea_thresholds_lstndvi.csv")
impacted_spei = read.csv("impactarea_threshold_spei_monthly.csv")

# ----------------------------------------------------------------------------------------------- #
# Styling
# ----------------------------------------------------------------------------------------------- #
rangeSMI = seq(0, 0.45, by=0.05)
rangeSPEI = NULL

nacol = "transparent"
pal1 = colorNumeric(c("transparent", "#a90480", "#e4ff15"), -7:-1, na.color = nacol)
pal2 = colorNumeric(c("transparent", "#a90480", "#e4ff15","#15a9ff"), -2.5:2.5, na.color = nacol)
pal3 = colorNumeric(c("transparent", "#a90480", "#e4ff15"), rangeSMI, na.color = nacol)
pal4 = colorNumeric(c("transparent", "#ffd815", "#d30000"), rangeSMI, na.color = nacol)
trendpal = colorNumeric(c("transparent", "#34ff1500", "#ffd500"), 0:1, na.color = nacol)
peakpal = colorNumeric(c("transparent", "#ffd815", "#d30000"), 0:10, na.color = nacol)

polygoncolor = NULL

lpos = "bottomleft"

# ----------------------------------------------------------------------------------------------- #
# UI
# ----------------------------------------------------------------------------------------------- #
ui = fluidPage(
  theme = bslib::bs_theme(bootswatch = "sandstone"),
  titlePanel("Drought hazard, vulnerability, and impacts for agriculture in Brandenburg"),

  # Selection menu, sliders and buttons
  sidebarLayout(
    sidebarPanel(
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
      sliderInput('speiyear', 'Year (raw)', 2013, 2022, 2018, sep=""),
      sliderInput('speith', 'SPEI Threshold (frequency)', -2.5, -0.5, -0.5, step=0.5),
      sliderInput('smith', 'SMI Threshold (frequency)', 0, 0.45, 0.05, step=0.05)
    ),
      # Slider to separately change the threshold for soil drought magnitude - merge?
      conditionalPanel(
      condition = "input.tabselector == 'Hazard'",
      sliderInput('th', 'Soil Drought Magnitude Threshold', 1, 40, 1)
    ),
      # Switch to display the exposure table as absolute hectare or percent change
      conditionalPanel(
      condition = "input.tabselector == 'Exposure'",
      selectInput('lk', 'Landkreis', lks),
      selectInput('expmode', "Absolute [ha] | Change [%]", c("Absolute", "Change"))
    ),
      # Complex panel for interactive weighting of the vulnerability indicators
      # - probably should be removed?
      conditionalPanel(
      condition = "input.tabselector == 'Vulnerability'",
      radioButtons("weighting_method", "Weighting Method:",
        c("PCA (all variables)" = "pcaw",
          "Equal Weights" = "ew",
          "Manual Weights" = "mw"), selected="pcaw"),
      checkboxGroupInput("user_settings", "Variables to include:",
        c("Agricultural population density" = "s1",
          "Dependency on agriculture for livelihood" = "s2",
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
          "Investment in disaster prevention and preparedness" = "c2")),
      #selectInput('lname', 'Layer', c("WSC", "WSC_n", "CS1_n"))
      sliderInput(inputId = "weight_s1", label = "Agricultural population density",
                  min = 0, max = 1, step= 0.1, value = 1),
      sliderInput(inputId = "weight_s2", label = "Dependency on agriculture for livelihood",
                  min = 0, max = 1, step= 0.1, value = 1),
      sliderInput(inputId = "weight_s3", label = "Education",
                  min = 0, max = 1, step= 0.1, value = 1),
      sliderInput(inputId = "weight_s4", label = "GDP per capita",
                  min = 0, max = 1, step= 0.1, value = 1)
    )
  ),
  # Arrangement of displayed outputs
  mainPanel(
    tabsetPanel(
      id = "tabselector", type = "tabs",
      tabPanel("Hazard", uiOutput("hazard")),
      tabPanel("Exposure", div(dataTableOutput(outputId = "exposure"), style = "font-size:50%")),
      tabPanel("Vulnerability", plotOutput(outputId = "vulnerability")),
      tabPanel("Impacts", uiOutput("impacts")),
      tabPanel("Crop Model", leafletOutput("cropmodel"))
    )
  )
) # sidebar
) # page

# ----------------------------------------------------------------------------------------------- #
# Server
# ----------------------------------------------------------------------------------------------- #
server = function(input, output){
  # init reactive values and observer for click events
  rv_location = reactiveValues(id=NULL,lat=NULL,lng=NULL)
  rv_shape = reactiveVal(FALSE)
  observe(shinyjs::toggle(id = "tabselector", condition = ifelse(input$tabs == 'Mapview', TRUE, FALSE)))
  
  # Hazard indicators SPEI-Magnitude and SMI-Total as synced maps
  output$hazard = renderUI({
    # Raw values of the SPEI and SMI layers
    if(input$speimode == "raw"){
      speilayer = get(paste0("spei_", input$speimonth))
      smilayer = get(paste0("smi_", input$smimonth))
      if(input$smimonth == "total"){smilayer = smilayer/100}
      if(input$speimonth == "magnitude"){speipal =  pal1} else {speipal =  pal2}
      if(input$smimonth == "magnitude"){smipal =  pal3} else {smipal =  pal4}
      m1 = leaflet() %>% addProviderTiles(providers$CartoDB.Positron) %>%
          addRasterImage(speilayer[[(input$speiyear-2012)]], colors = speipal, opacity = 0.8) %>%
          addLegend(pal = speipal, values = -2.5:2.5, title = "SPEI", position = lpos)
      m2 = leaflet() %>% addProviderTiles(providers$CartoDB.Positron) %>%
          addRasterImage(smilayer[[(input$speiyear-2012)]], colors = smipal, opacity = 0.8) %>%
          addLegend(pal = smipal, values = rangeSMI, title = "SMI",  position = lpos)
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
  output$exposure = renderDataTable({
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
      decadal_change = round((((t1 %>% dplyr::filter(year==2022)) - (t1 %>% dplyr::filter(year==2013))) / (t1 %>% dplyr::filter(year==2013)))*100, 0) %>% dplyr::select(-year)
      dfout = rbind.data.frame(dfout, cbind(year_dif = "2022 to 2013", decadal_change))
      dfout = datatable(dfout)
      return(dfout %>% formatStyle(columns=colnames(t4), color = styleInterval(0, c("red", "green"))))
    }
  })#, spacing='xs', striped=T)

  # Vulnerabiliy weighted indicator map
  output$vulnerability = renderPlot({
    if(input$weighting_method == "ew"){
      vdata = vdata[, input$user_settings]
      if(length(input$user_settings) == 1){
        plot(vulnerability[input$user_settings])
      } else if (length(input$user_settings) > 1){
        vulnerability$vi = rowMeans(vdata)
        plot(vulnerability["vi"])
      }
    } else if(input$weighting_method == "pcaw"){
      plot(vulnerability["WSC_n"])
    } else if(input$weighting_method == "mw"){
      vdata$weight_s1 = input$weight_s1
      vdata$weight_s2 = input$weight_s2
      vdata$weight_s3 = input$weight_s3
      vdata$weight_s4 = input$weight_s4
      vulnerability$vi = (vdata$s1 * vdata$weight_s1 + vdata$s2 * vdata$weight_s2 +
                          vdata$s3 * vdata$weight_s3 + vdata$s4 * vdata$weight_s4) / 4
      plot(vulnerability["vi"])
    }
  })

  # Impacts on field level (LST/NDVI-Anom.) AND on county level (EUR/ha) as synced maps
  output$impacts = renderUI({
      labelText = sprintf("<strong>%s</strong><br/>%s €.ha<sup> -1</sup>",
                          impacts$NUTS_NAME,
                          round(impacts[[paste0("aloss", input$yr)]], 1)) %>% lapply(htmltools::HTML)
       m1 = leaflet() %>% addProviderTiles(providers$CartoDB.Positron) %>%
            addGlPolygons(data = indicators %>% dplyr::filter(year==input$yr) %>% st_cast(to="POLYGON"), 
                          color="red",  popup = "type", group = "pols")
       m2 = leaflet(impacts) %>% 
              addProviderTiles(providers$CartoDB.Positron) %>%
              addPolygons(layerId = impacts$NUTS_NAME, color = "#444444", weight = 1, smoothFactor = 0.5, opacity = 1.0,
              fillOpacity = 0.5, fillColor = ~colorQuantile("YlOrRd", get(paste0("aloss", input$yr)))(get(paste0("aloss", input$yr))),
              highlightOptions = highlightOptions(color = "white", weight = 2, bringToFront = TRUE),
              label = lapply(labelText, htmltools::HTML))
       sync(m1, m2)
  })

  # Crop model visualization
  output$cropmodel = renderLeaflet({
    cropraster = get(paste0("cropmodel_", input$croptype))
    vals = values(cropraster[[input$yr - 2012]])
    cropmodelpal = colorNumeric(c("#0C2C84", "#41B6C4", "#FFFFCC"), vals, na.color = nacol)
    leaflet() %>% addProviderTiles(providers$CartoDB.Positron) %>%
      addRasterImage(cropraster[[input$yr - 2012]], colors = cropmodelpal, opacity = 0.8) %>%
      addLegend(pal = cropmodelpal, values = vals, title = "Wheat WLP")
  })
}

# ----------------------------------------------------------------------------------------------- #
# Run App
# ----------------------------------------------------------------------------------------------- #
shinyApp(ui = ui, server = server)