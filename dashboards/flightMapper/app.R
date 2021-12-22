# Libraries
options("rgdal_show_exportToProj4_warnings"="none")
library(shiny)
library(leaflet)
library(rgdal)
library(raster)
library(RColorBrewer)
#library(geosphere) The Airport Lines were arched with this library in a pre-processing step
library(shinythemes)
library(stringr)

# Load Helper Functions
source('./helper/functions.R')

set.seed(1.618)

### Initialize ###
# Load Data
airports  <- readOGR("./data/airports.gpkg",verbose = F)
airRoutes <- readOGR("./data/airRoutes.gpkg",verbose = F)
# Set Delay Class
airRoutes$delayTime <- 0
airRoutes$delayTime[airRoutes$theDelay == "0.5 to 2 hrs"] <- runif(sum(airRoutes$theDelay == "0.5 to 2 hrs"),0.5,2)
airRoutes$delayTime[airRoutes$theDelay == "2 to 4 hrs"] <- runif(sum(airRoutes$theDelay == "2 to 4 hrs"),2.01,4)
airRoutes$delayTime[airRoutes$theDelay == "4+ hrs"] <- runif(sum(airRoutes$theDelay == "4+ hrs"),4.01,8)
airRoutes$delayTime <- round(airRoutes$delayTime,2)
# Load Snow Raster
theSnow <- raster('./data/snowStorm.tif')

### UI ###
# First Page
ui <- navbarPage(div(tags$head(tags$style(HTML("hr {border-top: 1px solid #000000;}"))),
                     "PortWatch Demo"),
                 theme=shinytheme('cosmo'),
                 id='portWatchPage',
                 windowTitle = 'Peter Watson - PortWatch Demonstration',
                 tabPanel(title = "Welcome", value = "welcome",
                          a(img(src="portWatchLogo.png", width = 300), href = "https://www.docwatson.ai/", target="_blank", rel="noopener noreferrer"),
                          h4("Welcome to ", tags$strong('PortWatch')," - an AI-based real-time sensing and decision support tool. 
                          PortWatch combines real-time remote sensing with machine learning models to estimate the air freight and passenger flight delays from upcoming weather event. 
                          Its various modules can be used by logisitics operations managers, emergency responders and others to gain situational intelligence, prepare, and respond to severe weather events.", tags$p(), 
                             "You are currently looking at a demonstration tool prepared for the continental United States. The data presented here is for illustration only and does not represent actual estimates of damages for any particular storm or flight. The data shown 
                          is derived from a climatological analysis, and the primary purpose is to help visualize what a system might look like.  To take a look check the tabs above, or push the button!"),
                          actionButton("mapGo", label ="GO!")
                 ),
                 # Map Page
                 tabPanel(title = 'Air Freight Delays',value='airports',
                          h2(div(tags$b("Expected Weather-Related Air Delays:"))),
                          leafletOutput("airMap", height = 1000)
                 ),
                 # Explaination Page
                 tabPanel('About',
                          h1('About PortWatch'),
                          h3(tags$strong('PortWatch'),'is based on the data-driven impact modeling approaches developed by Peter Watson and the University of Connecticut. 
		                  It uses proprietary techniques for combining historical datasets of weather observations, impacts and risk 
		                  factors into machine learning models.', tags$p(), 
                             "To learn more, please check out ",a(href='https://docwatson.ai','www.docwatson.ai'))
                 ))

###############                          
# The Server #
##############
server <- function(input, output, session) {
  # Event for Button Press
  observeEvent(input$mapGo,{
    updateNavbarPage(session, "portWatchPage",selected = "airports")
  })
  
  ###################
  # Airport Tab #
  ###################
  output$airMap   <- renderLeaflet({
    # Load Map Data
    theMap <- airRoutes
    # Delay Colors
    theColors <- colorFactor(c('gold1','darkorange1','red2'), theMap$theDelay)
    # Snow Colors
    colorsOfTheSnow <- colorNumeric("BuPu", values(theSnow),na.color = "transparent")
    # Mouse Over
    labels <- sprintf(
      "<strong>Origin: %s</strong><br/>
      <strong>Destination: %s</strong><br/>
      <b>Expected Delay:</b> %s hrs",
      theMap$SrcPort, theMap$DestPort, theMap$delayTime) %>% lapply(htmltools::HTML)
    # Leaflet Map
    leaflet(theMap) %>% 
      # Set Background Map Style
      addProviderTiles(providers$Stamen.TonerLite) %>%
      # Set starting view
      setView(-94.6, 39.0, zoom = 5) %>%
      # Add Snow Layer
      addRasterImage(theSnow, opacity = 0.8, colors = colorsOfTheSnow, group = 'Snowfall') %>%
      # Add Flight Path Line Layer
      addPolylines(color = ~theColors(theDelay),
                   label = labels,
                   weight = 2,
                   highlightOptions = highlightOptions(weight = 3, bringToFront = TRUE),
                   opacity = 0.7,
                   fillOpacity = 0.7,
                   labelOptions = labelOptions( textsize = "15px"),
                   group='Flight Delay') %>%
      # Add Delay Legend
      addLegend("topleft", pal = theColors, values = ~theDelay,
                title = "Expected Flight Delay",
                opacity = 1) %>%
      # Add Snow Legend
      addLegend("topleft", pal = colorsOfTheSnow, values = values(theSnow),
                title = "Snowfall",
                opacity = 1) %>%
      # Add Layer Control Menu
      addLayersControl(
        overlayGroups = c("Snowfall", "Flight Delay"),
        options = layersControlOptions(collapsed = FALSE))
  })
}
# Run it
shinyApp(ui, server)
