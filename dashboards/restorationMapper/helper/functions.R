# Shiny Modules
valFn <- function(x){round(x,1)}
minFn <- function(x){max(round(x) - 10,0.1)}
maxFn <- function(x){min(round(x) + 10,Inf)}

sliderNumUI <- function(areaCode){
  ns <- NS(areaCode)
  uiOutput(ns("sliderNum"))
}

# Define Behavior given a Name Space...
sliderNumCooker <- function(id,area,crewValues){
  moduleServer(id,
               function(input,output,session){
                 ns <- session$ns
                 output$sliderNum <- renderUI(splitLayout(cellWidths = c("20%", "80%"),
                                                          textInput(ns('Number'), area, value = 1), 
                                                          sliderInput(ns('Slider'),NULL,min=0, max=10, value=1, step=0.1)))
                 
                 observeEvent(input$Slider,{
                   updateSliderInput(session, 'Slider', min = minFn(input$Slider), max = maxFn(input$Slider))
                   updateTextInput(session, 'Number', value = input$Slider)
                   backVal <- crewValues[[id]]
                   if (abs(backVal-input$Slider) > 0.1){
                      crewValues[[id]] <- input$Slider
                      }
                 })
                 observeEvent(input$Number,{
                   val <- as.numeric(input$Number)
                   backVal <- crewValues[[id]]
                   if(val != '' & !is.na(val) & val > 0 & abs(val-backVal) > 0.1){
                        updateSliderInput(session, 'Slider', value = val, min = minFn(val), max = maxFn(val))
                        crewValues[[id]] <- val
                    }
                   })
                 observe({
                   updateSliderInput(session, 'Slider', value = crewValues[[id]], min = minFn(crewValues[[id]]), max = maxFn(crewValues[[id]]))
                   updateNumericInput(session, 'Number', value = round(crewValues[[id]],1))
                 })
                 })
                 
               }
