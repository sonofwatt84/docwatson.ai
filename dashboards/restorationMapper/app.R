library(shiny)
library(leaflet)
library(rgdal)
library(rgeos)
library(RColorBrewer)
library(highcharter)

source('./helper/functions.R')

### Initialize ###
# Load Data
fullAreaFrame <- read.csv('./data/athnEventData.csv')
areaShapes <- readOGR('./data/ATHENSarea.shp', verbose = F)
theCents <- gCentroid(areaShapes,byid=T)
# Order the shapefile entries
areaShapes <- areaShapes[order(areaShapes$PYR_YPIRES),]
# Specify the Name variable
areaVar <- "NAME"

# Define Input Names
theAreas <- as.data.frame(areaShapes)[,areaVar]
nAreas   <- length(theAreas)
areaCodes <- abbreviate(theAreas,2)

### UI ###
ui <- navbarPage(div(tags$head(tags$style(HTML("hr {border-top: 1px solid #000000;}"))
                              ),"DARM Demostration"),
                 id='darmPage',
		             windowTitle = 'Dr. Peter Watson - DARM Demonstration for Athens',
                 tabPanel(title = "Welcome", value = "welcome",
                          a(img(src="AthensFlag.png", width = 300), href = "https://en.wikipedia.org/wiki/Athens", target="_blank", rel="noopener noreferrer"),
                          h4("Welcome to ", tags$strong('DARM')," - an AI-based real-time sensing and decision support tool for emergency managers. 
                          DARM combines real-time remote sensing with machine learning models to estimate the damage from an ongoing weather event. 
                          Its various modules can be used by operations teams to gain situational intelligence, deploy repair crews, and estimate time to 
                          restoration.", tags$p(), 
                          "You are currently using a demonstration tool that has been customized for the area around Athens, Greece. The data that you will see 
                          in the various tabs are for illustration only and do not represent actual estimates of real damages. They have been 
                          imported from other simulations and their primary purpose is to help visualize what an eventual system might look like."),
                          actionButton("darmGo", label ="GO!")
                 ),
                 tabPanel(title = 'Damages',value='damages',
                          h2(div(tags$b("Predicted Total Trouble Spots:"),textOutput("totalDamage"))),
                          leafletOutput("damageMap", height = 600),
                          highchartOutput("hDamagePlot")
                          ),
                 tabPanel(title = 'Work Time',value = 'workTime',
                          h2(div(tags$b("Predicted Total Work Time:"),textOutput("totalWork"))),
                          leafletOutput("workMap", height = 600),
                          highchartOutput('hWorkPlot')
                          ),
                 tabPanel(title = 'Restoration Time', value = 'restTime',
                          sidebarLayout(
                            sidebarPanel(
                              h2(tags$b('Crew Allocation')),
                              numericInput("availCrew", "Available Crews", value = 14, min = 0, width = '150px'),
                              span(tags$b('Distribute Crews:'),tags$br(),actionButton("evenDist", label ="Evenly"),actionButton("optiDist", label ="Optimized")),
                              hr(),
                              span(tags$b('Total Allocated Crews:'), h3(uiOutput("allocCrew"))),
                              sliderNumUI(areaCodes[1]),
                              sliderNumUI(areaCodes[2]),
                              sliderNumUI(areaCodes[3]),
                              sliderNumUI(areaCodes[4]),
                              sliderNumUI(areaCodes[5]),
                              sliderNumUI(areaCodes[6]),
                              sliderNumUI(areaCodes[7]),
                              sliderNumUI(areaCodes[8]),
                              sliderNumUI(areaCodes[9]),
                              sliderNumUI(areaCodes[10]),
                              sliderNumUI(areaCodes[11]),
                              sliderNumUI(areaCodes[12]),
                              sliderNumUI(areaCodes[13]),
                              sliderNumUI(areaCodes[14])
                              ),
                            mainPanel(
                              h1(tags$b("Global Restoration Time:"),textOutput("restTime")),
                              leafletOutput("restMap", height = 600),
                              highchartOutput('hRestPlot'),
                              highchartOutput('hCrewPlot')
                            ))),
		      tabPanel('About',
		               h1('About DARM'),
		               h3(tags$strong('DARM'),'is the Damage Assessment and Restoration Model conceived of and developed by Peter Watson and collaborators at the University of Connecticut. 
		                  The DARM uses proprietary techniques for combining historical datasets of weather observations, impacts and risk 
		                  factors into machine learning models. For more info, check out ',a(href='http://www.docwatson.ai' ,'www.docwatson.ai'))
		      ))


###############                          
# The Server #
##############
server <- function(input, output, session) {
  

  restCalcer <- function(workTime,crewSize){round(workTime/(crewSize*0.8),2)}
  
  # Damage
  damgValues <- reactiveValues()
  
  for(aCode in areaCodes){
    damgValues[[aCode]] <- 0.1
  }
  theDamg <-  reactive({
    theList <- unlist(reactiveValuesToList(damgValues))
  })
  # Work
  workValues <- reactiveValues()
  
  for(aCode in areaCodes){
    workValues[[aCode]] <- 0.1
  }
  theWork <-  reactive({
    theList <- unlist(reactiveValuesToList(workValues))
  })
  # Crews
  crewValues <- reactiveValues()
  
  for(aCode in areaCodes){
    crewValues[[aCode]] <- 1
  }
  theCrews <-  reactive({
    theList <- unlist(reactiveValuesToList(crewValues))
  })

  eventData <- subset(fullAreaFrame, codeNames=="Bomb Cyclone")
  for (i in 1:nAreas){
    damgValues[[areaCodes[i]]] <- eventData$meanTS[i]
    workValues[[areaCodes[i]]] <- eventData$work50[i]
  }
  
  observeEvent(input$darmGo,{
    updateNavbarPage(session, "darmPage",selected = "damages")
    })
  
  
  output$eventType   <- renderText(input$eventID)

  ##############
  # Damage Tab #
  ##############
  output$totalDamage <- renderText(paste(round(sum(theDamg())),'locations'))
  
  output$damageMap   <- renderLeaflet({
    theData <- theDamg()[areaCodes]
    theMap <- cbind(areaShapes,theData)
    names(theMap)[ncol(theMap)] <- 'theDamg'
    theColors <- colorBin("YlOrRd", theData)
    
    labels <- sprintf(
      "<strong>%s</strong><br/><b>Damage:</b> %g TS ",
      theMap@data[,areaVar], round(theData)) %>% lapply(htmltools::HTML)
    
    leaflet(theMap,
            options = leafletOptions(zoomControl = FALSE,
                                     scrollWheelZoom = 'center')) %>% # Add Scroll Wheel Lock?
      addTiles() %>%
      addPolygons(color = "#444444", weight = 1, smoothFactor = 0.5,
                  opacity = 1.0, fillOpacity = 0.8,
                  fillColor = ~theColors(theDamg),
                  highlightOptions = highlightOptions(color = "white", weight = 2, bringToFront = TRUE),
                  label = labels,
                  labelOptions = labelOptions(
                    style = list("font-weight" = "normal", padding = "3px 8px"),
                    textsize = "15px",
                    direction = "auto")) %>%
      addLegend("topright", pal = theColors, values = ~theDamg,
                  title = "Trouble Spots",
                  opacity = 1) %>%
      addLabelOnlyMarkers(lat = theCents$y, lng = theCents$x,
                          label = round(theData),
                          labelOptions = labelOptions(noHide = T, 
                                                      direction = 'center', 
                                                      textOnly = T,
                                                      style = list(
                                                        "color"= 'white',
                                                        "font-weight" = "bold",
                                                        "text-shadow" = '2px 2px #282828',
                                                        "-webkit-text-stroke-width"= "1px",
                                                        "-webkit-text-stroke-color"= "black"),
                                                      textsize = "20px",
                                                      opacity = 1))
    })
  
  output$hDamagePlot <- renderHighchart ({
    eventData <- areaShapes@data
    theData <- theDamg()[areaCodes]
    eventData <- cbind(eventData,theData)
    names(eventData)[ncol(eventData)] <- 'theDamg'
    eventData$theColors <- colorBin("YlOrRd", theData)(theData)
    eventData$Area <- eventData[,areaVar]
    
    hchart(eventData, 'column', hcaes(x = Area, y = theDamg, name=Area, color=theColors),name = "Damage Locations") %>%
      #hc_add_series(data = eventData$workSTDcats) %>%
      hc_xAxis(title = list(text='Area')) %>%
      hc_yAxis(title = list(text='Damage Locations')) %>%
      hc_title(text='Estimated Damages by Area',align="center") %>%
      hc_tooltip(crosshairs = TRUE, 
                 #useHTML = TRUE,
                 backgroundColor = "#FCFFC5",
                 pointFormat = '<b>Damage Locations:</b> {point.y} TS ',
                 shared = TRUE,
                 #table=TRUE,
                 borderWidth = 2,
                 valueDecimals = 0)
    
  }) 
  #################
  # Work Time Tab #
  #################
  
  output$totalWork <- renderText(paste("Total Work Time:",round(sum(theWork())),'hrs'))
  
  output$workMap   <- renderLeaflet({
    theData <- theWork()[areaCodes]
    theMap <- cbind(areaShapes,theData)
    names(theMap)[ncol(theMap)] <- 'theWork'
    theColors <- colorBin("PuRd", theData)
    labels <- sprintf(
      "<strong>%s</strong><br/><b>Work:</b> %g Hrs ",
      theMap@data[,areaVar], round(theData,2)) %>% lapply(htmltools::HTML)
    
    
    leaflet(theMap,
            options = leafletOptions(zoomControl = FALSE, 
                                     scrollWheelZoom = 'center')) %>%
      addTiles() %>%
      addPolygons(color = "#444444", weight = 1, smoothFactor = 0.5,
                  opacity = 1.0, fillOpacity = 0.8,
                  fillColor = ~theColors(theData),
                  highlightOptions = highlightOptions(color = "white", weight = 2,bringToFront = TRUE),
                  label = labels,
                  labelOptions = labelOptions(
                    style = list("font-weight" = "normal", padding = "3px 8px"),
                    textsize = "15px",
                    direction = "auto")) %>%
      addLegend("topright", pal = theColors, values = ~theWork,
                 title = "Work Time",
                 labFormat = labelFormat(suffix = "hrs"),
                 opacity = 1) %>%
      addLabelOnlyMarkers(lat = theCents$y, lng = theCents$x,
                          label = round(theData),
                          labelOptions = labelOptions(noHide = T, 
                                                      direction = 'center', 
                                                      textOnly = T,
                                                      style = list(
                                                        "color"= 'white',
                                                        "font-weight" = "bold",
                                                        "text-shadow" = '2px 2px #282828',
                                                        "-webkit-text-stroke-width"= "1px",
                                                        "-webkit-text-stroke-color"= "black"),
                                                      textsize = "20px",
                                                      opacity = 1))
  })
  
  output$hWorkPlot <- renderHighchart ({
    eventData <- areaShapes@data
    theData <- theWork()[areaCodes]
    eventData <- cbind(eventData,theData)
    names(eventData)[ncol(eventData)] <- 'theWork'
    eventData$theColors <- colorBin("YlOrRd", theData)(theData)
    eventData$Area <- eventData[,areaVar]
    eventData$theColors <- colorBin("PuRd", theData)(theData)
    
    hchart(eventData, 'column', hcaes(x = Area, y = theWork, color=theColors),name = "Work Time") %>%
      #hc_add_series(data = eventData$workSTDcats) %>%
      hc_xAxis(title = list(text='Area')) %>%
      hc_yAxis(title = list(text='Work Time (hrs)')) %>%
      hc_title(text='Estimated Work Time by Area',align="center") %>%
      hc_tooltip(crosshairs = TRUE, 
                 #useHTML = TRUE,
                 backgroundColor = "#FCFFC5",
                 pointFormat = '<b>Work Time:</b> {point.y} Hrs ',
                 shared = TRUE,
                 borderWidth = 2,
                 valueDecimals = 0)
  })
  
  ########################
  # Restoration Time Tab #
  ########################
  
  sliderNumCooker(areaCodes[1], area = theAreas[1], crewValues)
  sliderNumCooker(areaCodes[2], area = theAreas[2], crewValues)
  sliderNumCooker(areaCodes[3], area = theAreas[3], crewValues)
  sliderNumCooker(areaCodes[4], area = theAreas[4], crewValues)
  sliderNumCooker(areaCodes[5], area = theAreas[5], crewValues)
  sliderNumCooker(areaCodes[6], area = theAreas[6], crewValues)
  sliderNumCooker(areaCodes[7], area = theAreas[7], crewValues)
  sliderNumCooker(areaCodes[8], area = theAreas[8], crewValues)
  sliderNumCooker(areaCodes[9], area = theAreas[9], crewValues)
  sliderNumCooker(areaCodes[10], area = theAreas[10], crewValues)
  sliderNumCooker(areaCodes[11], area = theAreas[11], crewValues)
  sliderNumCooker(areaCodes[12], area = theAreas[12], crewValues)
  sliderNumCooker(areaCodes[13], area = theAreas[13], crewValues)
  sliderNumCooker(areaCodes[14], area = theAreas[14], crewValues)
  
  theRests <- reactive({restCalcer(theWork()[areaCodes],theCrews()[areaCodes])})
  
  observeEvent(input$optiDist, {
    nAreas <- length(theAreas)
    works <- as.vector(theWork()[areaCodes])
    nCrews <- input$availCrew
    theWeights <- works/sum(works)
    optiVec <- theWeights * nCrews  # Your model weights & Total Crews
    # Update Reactive Space with Crews
    for (i in 1:nAreas){
      crewValues[[areaCodes[i]]] <- optiVec[i]
    }
  })
  
  observeEvent(input$evenDist, {
    nAreas <- length(theAreas)
    nCrews <- input$availCrew
    evenVec <- rep(nCrews/nAreas,nAreas)
    for (i in 1:nAreas){
      crewValues[[areaCodes[i]]] <- evenVec[i]
    }
  })

  output$restMap   <- renderLeaflet({
    crews <- theCrews()[areaCodes]
    theMap <- cbind(areaShapes,theRests())
    names(theMap)[ncol(theMap)] <- 'restTime'
    restBins <- c(0, 8, 24, 48, 72, 96, Inf)
    theColors <- colorBin("Reds", bins=restBins)
    
    labels <- sprintf(
      "<strong>%s</strong><br/>Restoration Time:<br /> %g hours<br /> Crew Allocation:<br /> %g Crews",
      theMap@data[,areaVar], round(theMap$restTime,1), round(crews,2)
    ) %>% lapply(htmltools::HTML)
    
    leaflet(theMap,
            options = leafletOptions(zoomControl = FALSE,
                                     scrollWheelZoom = 'center')) %>%
      addTiles() %>%
      addPolygons(color = "#444444", weight = 1, smoothFactor = 0.5,
                  opacity = 1.0, fillOpacity = 0.8,
                  fillColor = ~theColors(restTime),
                  highlightOptions = highlightOptions(color = "white", weight = 2,bringToFront = TRUE),
                  label = labels,
                  labelOptions = labelOptions(
                    style = list("font-weight" = "normal", padding = "3px 8px"),
                    textsize = "15px",
                    direction = "auto")) %>%
      
      addLegend("topright", pal = theColors, values = ~restTime,
                title = "Restoration Time",
                labFormat = labelFormat(suffix = " hrs"),
                opacity = 1) %>%
    
      addLabelOnlyMarkers(lat = theCents$y, lng = theCents$x,
                          label = round(theMap$restTime),
                          labelOptions = labelOptions(noHide = T, 
                                                      direction = 'center', 
                                                      textOnly = T,
                                                      style = list(
                                                        "color"= 'white',
                                                        "font-weight" = "bold",
                                                        "text-shadow" = '2px 2px #282828',
                                                        "-webkit-text-stroke-width"= "1px",
                                                        "-webkit-text-stroke-color"= "black"),
                                                      textsize = "20px",
                                                      opacity = 1))
  })
  
  output$hRestPlot <- renderHighchart ({
    restData <- theRests()
    restBins <- c(0, 8, 24, 48, 72, 96, Inf)
    theColors <- colorBin("Reds", bins=restBins)(restData)
    restFrame <- data.frame(Area = theAreas, theRests = restData, theColors = theColors)
    
    hchart(restFrame, type = 'column', hcaes(x = Area, y = theRests, color=theColors),name = "Restoration Time") %>%
      hc_xAxis(title = list(text='Area')) %>%
      hc_yAxis(title = list(text='Restoration Time (hrs)')) %>%
      hc_title(text='Estimated Restoration Time by Area',align="center",style = list(fontWeight='bold')) %>%
      hc_tooltip(crosshairs = TRUE, 
                 #useHTML = TRUE,
                 backgroundColor = "#FCFFC5",
                 pointFormat = '<b>Restoration Time:</b> {point.y} Hrs',
                 shared = TRUE,
                 borderWidth = 2,
                 valueDecimals = 0)
    
  })
  
  output$hCrewPlot <- renderHighchart ({
    restData <- theRests()
    crewData <- theCrews()[areaCodes]
    restBins <- c(0, 8, 24, 48, 72, 96, Inf)
    theColors <- colorBin("Reds", bins=restBins)(restData)
    crewFrame <- data.frame(Area = theAreas, theCrews = crewData, theColors = theColors)
    
    hchart(crewFrame, type = 'column', hcaes(x = Area, y = theCrews, color=theColors),name = "Restoration Time") %>%
      hc_xAxis(title = list(text='Area')) %>%
      hc_yAxis(title = list(text='Crews')) %>%
      hc_title(text='Crew Allocations by Area',align="center",style = list(fontWeight='bold')) %>%
      hc_tooltip(crosshairs = TRUE, 
                 #useHTML = TRUE,
                 backgroundColor = "#FCFFC5",
                 pointFormat = '<b>Allocated Crews:</b> {point.y}',
                 shared = TRUE,
                 borderWidth = 2,
                 valueDecimals = 2)
    
  })
  
  output$restTime  <- renderText(paste(max(round(theRests())),'hrs'))
  
  observe({
    output$allocCrew <- renderUI({
        crewTotal <- round(sum(theCrews()),2)
        availCrew <- input$availCrew
        if(is.na(availCrew)){
          col <- "color:#201D1D"
        }else if (crewTotal > availCrew){
          col <- "color:#eb4c34"
        }else{
          col <- "color:#65c236"
        }
        tags$span(style = col, crewTotal)
    })
  })
}

shinyApp(ui, server)
