source('/Users/wesgroves/Documents/GitHub/SampleWork/XInsuranceComparisonInc/XInsuranceComparisonInc.R')

#Libraries
library(shiny)
library(plotly)
library(dplyr)
library(tidyr)

#App
if (interactive()) {
  
  ui <- fluidPage(
    
    titlePanel('X Insurance Comparison Inc.', 'X Insurance Comparison Inc.'),
    
    tabsetPanel(
      tabPanel(
        
        #Header
        headerPanel(title = "Metrics",
                    windowTitle = "X Insurance Comparison Inc. Metrics"),
        
        #Key Metrics
        sidebarLayout(
          sidebarPanel(
            selectInput(
              "y",
              label = h3("Metrics"),
              choices = data.frame(var = c('CallsPerTransfer',
                                           'RevPerTransfer',
                                           'RevPerCall',
                                           'PercentMargin'))
            ),
            selectInput(
              'group',
              label = h3("Groups"),
              choices = data.frame(var = c('Individual', 'Entire Team')),
              selected = 'Entire Team'),
            h5('Information: '),
            h6('You can double-click on an option in the legend to select or unselect all the other options.\n
             You may also click and drag your arrow to zoom in.\n
             Move your mouse to the top right of the graph for more tools.')
          ),
          mainPanel(
            plotlyOutput("myPlot")
          )
          )
      ),
      tabPanel(
        #Header
        headerPanel("Analyses",
                    "X Insurance Comparison Inc. Analyses"),
        
        #Analysis
        ##EDA - Exploratory Data Analysis
        sidebarLayout(
          sidebarPanel(
            checkboxGroupInput("campaigns","Grouping Options:",choices),
            actionLink("selectall","Select All"),
            checkboxGroupInput('density','Toggle Density Plot:','Density'),
            h5('Information: '),
            h6('You can double-click on an option in the legend to select or unselect all the other options.\n
               You may also click and drag your arrow to zoom in.\n
               Move your mouse to the top right of the graph for more tools.')
            ),
          mainPanel(plotlyOutput("myAnalysis"))
            )
        ,
        ##Modeling----------------
        h2('Modeling Calls Per Transfer'),
        checkboxGroupInput("factors","Factors To Consider:",
                           c('Weekdays', 'Holidays')),
        mainPanel(tableOutput('analysis'))
        
        )
      )
  )
  
  
  
  server <- function(input, output, session) {
    
    ##############
    ##Key Metrics#
    ##############
    
    vals <- reactiveValues(a = NULL)
    observeEvent(input$group, {
      
      vals$a <- input$group    
      
      if(vals$a == 'Individual') {
        
        output$myPlot = renderPlotly({
          df_reactive = reactive(df)
          medians_reactive = reactive(df_medians)
          plot_ly(data=df_reactive(), x=df$Date, y=~get(input$y), type = 'scatter', mode = 'lines',
                  name = df$Person) %>% 
            layout(yaxis = list(title = input$y)) %>% 
            add_trace(data = medians_reactive(),
                      x = ~Date,
                      y = ~get(input$y),
                      name = 'Daily Median Value')
        })
        
      }
      else {
        
        output$myPlot = renderPlotly({
          df_overall_reactive <- reactive(df_overall)
          p = plot_ly(data=df_overall_reactive(),
                      x=df_overall$Date,
                      y=~get(input$y),
                      type = 'scatter',
                      mode = 'lines',
                      name = input$y) %>%
            layout(yaxis = list(title = input$y)) %>%
            add_trace(y = ~mean(get(input$y)),
                      name = 'Year-To-Date Mean')
          #If input is PercentMargin, add extra lines
          if(input$y == 'PercentMargin') {
            p = add_trace(p, y = df_overall$MinMargin,
                          name = 'Daily Min') %>%
              add_trace(y = df_overall$MaxMargin,
                        name = 'Daily Max') #%>%
            # add_trace(y = ~WesMargin,
            #           name = 'Wes')
          }
          p
        })
        
      } 
    }
    )
    
    ###########
    ##Analysis#
    ###########
    
    #select all button
    observe({
      if(input$selectall == 0) return(NULL) 
      else if (input$selectall%%2 == 0)
      {
        updateCheckboxGroupInput(session,"campaigns","Choose one or more:",choices=choices)
      }
      else
      {
        updateCheckboxGroupInput(session,"campaigns","Choose one or more:",choices=choices,selected=choices)
      }
    })
    
    #Checkbox responses for EDA
    observe({
      if (length(input$campaigns) == 0) {
        output$myAnalysis = renderPlotly({
          temp = df_analysis %>%
            select(CallsPerTransfer)
          reactive_none = reactive(temp)
          p <- ggplot(reactive_none(), aes(x=`CallsPerTransfer`))
          if (length(input$density) == 0) {
            p = p +
              geom_histogram(fill = 'red', alpha = .4, position = 'identity', 
                             binwidth = median(temp$CallsPerTransfer)/5)
          } else {
            p = p +
              geom_density(fill = 'red', alpha = .4)
          }
          ggplotly(p)
        })
      } 
      if (length(input$campaigns) > 0) {
        output$myAnalysis = renderPlotly({
          selections <- names(df_analysis)[names(df_analysis) %in% c(input$campaigns)]
          temp = df_analysis %>% 
            select(selections, CallsPerTransfer) %>% 
            unite('Key', selections[1]:selections[length(selections)], sep = ' ')
          df_reactive1 = reactive(temp)
          p <- ggplot(df_reactive1(), aes(x=`CallsPerTransfer`))
          if (length(input$density) == 0) {
            p = p +
              geom_histogram(aes(group=`Key`, fill=`Key`), alpha = .4, position = 'identity',
                             binwidth = median(temp$CallsPerTransfer)/5)
          } else {
            p = p +
              geom_density(aes(group=`Key`, fill=`Key`), alpha = .4)
          }
          ggplotly(p)
        })
      }
    })
    
    #Checkbox responses for Analysis-----------
    observe({
      if(length(input$factors) == 0) {
        overall_mean <- data.frame(sum(df_overall$Calls)/sum(df_overall$Transfers))
        colnames(overall_mean) <- 'Year-To-Date Calls Per Transfer'
        rownames(overall_mean) <- ''
        output$analysis <- renderTable(overall_mean, rownames = T)
      }
      if(length(input$factors) == 2) {
        output$analysis <- renderTable(df_both, rownames = T)
      }
      if (length(input$factors) == 1) {
        if ('Holidays' %in% input$factors) {
          output$analysis <- renderTable(df_holiday, rownames = T)
        } else {
        output$analysis <- renderTable(df_weekday, rownames = T)
        }
      }
      })
    
    
    
  } #end server function
  
  shinyApp(ui = ui, server = server)
  
}