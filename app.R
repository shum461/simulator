library(shiny)
library(httr2)
library(shinyjs)
library(jsonlite)
library(bslib)
library(lixoftConnectors)
library(shinyFiles)
library(shinyAce)
library(tidyverse)
library(shinychat)
library(ellmer)
library(promises)
library(highcharter)
#document collection on embedding.io
# EMBEDDING_IO_API_KEY <- Sys.getenv("EMBEDDING_IO_API_KEY")
# COLLECTION_ID <- "col_yWQYjbDkzwX6ZD"
# PINECONE_API_KEY=Sys.getenv("PINECONE_API_KEY")
# 
# # my personal key (don't abuse it)
# OPENAI_API_KEY <- Sys.getenv("OPENAI_API_KEY")

# embedding.io function
# https://github.com/wch/llm-chat/blob/main/rag-chat/app.R


# initialize connectors
lixoftConnectors::initializeLixoftConnectors(
  software = "monolix",
  path = "/srv/Lixoft/MonolixSuite2024R1/",
  force = TRUE)




# extra prompt
extra_prompt <- readLines("scripts/defineTreatmentElement_docs") %>%
  paste(., collapse = " ")

source("scripts/get-embeddings.R")
source("scripts/initial-prompt.R")
source("scripts/chat_bot_ui.R")
source("scripts/chat_bot_server.R")
source("scripts/sidepanel_inputs_ui.R")
source("scripts/sidepanel_inputs_server.R")
source("scripts/ace_editor_ui.R")
source("scripts/ace_editor_server.R")
#initial_system_prompt <-paste0(initial_system_prompt,extra_prompt)

# UI ----------------------------------------------------------------------

ui <-  page_sidebar(
  theme = bs_theme(version = 5),
  useShinyjs(),
  sidebar = sidebar(width = '350px',
      h3("Simulator"),
      sidepanel_inputs_ui("sidepanel_inputs"),
      verbatimTextOutput("filename"),
      # Add a pickerInput for covariates
      shinyjs::hidden(selectInput(
        inputId = "covariates_picker",
        label = "Model Covariates",
        choices = NULL,
        multiple=TRUE
      )),
      shinyFilesButton(id = "shinyfilesbtn",
                       title = "Select project file",
                       label = "Choose monolix project",
                       multiple = FALSE
                       
      ),
      # tags$style(type = "text/css", ".shiny-output-error {visibility: hidden;}"),
      # tags$style(type = "text/css", ".shiny-output-error:before {content: 'Check your inputs or API key';}"),
      # tags$style(type = "text/css", "label {font-weight: bold;}")
      ),
navset_card_tab(
  nav_panel("GPT API",
            card(
              card_title("Chat GPT"),
              height = "100px",
              class='card border-0',
              chat_bot_ui("chat_bot")
            )
          ),
nav_panel(
  "Model",
  ace_editor_ui("ace_editor")
    ),
nav_panel(
  "Conc Plots",
  highchartOutput("concentration_plot")
),
nav_panel(
  "Conc Table",
  DT::DTOutput("concentration_table")
)

)
)

# Server --------------------------------------------------------------------
server <- function(input, output, session) {
  


  volumes <- reactive({
    c(
    Demos = lixoftConnectors::getDemoPath(),
    Home = fs::path_home(),
    "R Installation" = R.home(),
    getVolumes()()
  )})
  
  # Covariates from monolix files
  observe({
    
    covariates_value <- covariates()
    
    
    if (!is.null(covariates_value) && covariates_value != "") {
      # Split the covariates string into a vector
      covariates_vector <- strsplit(covariates_value, ",\\s*")[[1]]
      covariates_df <- data.frame(Covariates = covariates_vector, stringsAsFactors = FALSE)
      
      shinyjs::show("covariates_picker") 

      updateSelectInput(
        session = session,
        inputId = "covariates_picker",
        choices = covariates_df$Covariates,
        selected = covariates_df$Covariates
      )
    } else {
      shinyjs::hide("covariates_picker") 
    }
    
    
  simulations_results_value <- simulation_results()
  
  req(simulation_results())
  print(simulations_results_value) 
  
    
  })
  
  # format for highcharter
  
  series_data <- reactive({
    req(simulation_results())
    
    simulations_results_value <- simulation_results()
    concentrations <- simulations_results_value$res$CONC
    
     concentrations  %>%
      group_by(id) %>%
      summarise(
        data = list(map2(time, CONC, ~ list(x = .x, y = .y)))  
      ) %>%
      mutate(series = map2(id, data, ~ list(name = paste("id", .x), data = .y)))
  })
  
  # Render Highcharter plot
  output$concentration_plot <- renderHighchart({
    req(series_data())
    
    highchart() %>%
      hc_chart(type = "line") %>%
      hc_title(text = "Time vs Concentration by ID") %>%
      hc_xAxis(title = list(text = "Time")) %>%
      hc_yAxis(title = list(text = "Concentration")) %>%
      hc_add_series_list(series_data()$series) %>%
      hc_tooltip(
        pointFormat = "Time: {point.x} <br> Concentration: {point.y}"
      )
  })
  
  output$concentration_table <- DT::renderDT({
    
    req(simulation_results())
    
    simulations_results_value <- simulation_results()
    concentrations <- simulations_results_value$res$CONC
    
    DT::datatable(data = concentrations)
    
  })
  
  
  project_file_path <- reactiveVal()

  # # Update project file path when a file is selected
  observeEvent(input$shinyfilesbtn, {
    req(input$shinyfilesbtn)
    imported_project <- parseFilePaths(volumes(), input$shinyfilesbtn)
    project_file_path(imported_project)
  })
  
  
  observeEvent(input$shinyfilesbtn, {
    
    shinyFileChoose(
      input,
      id = "shinyfilesbtn",
      roots = volumes(),  # Notice the () here to evaluate the reactive
      session = session,
      filetypes = c("mlxtran")
    )
    
  })
  
  # Render text output for file name
  output$filename <- renderText({
    req(input$shinyfilesbtn)
    req(nchar(project_file_path() >5))
    project_file_path()$name
    })


  # 
  # model NULL in ellmer will choose one
  model_choice <- reactive({
    if(isTruthy(input$model_name)) {
      input$model_name
    } else{
      NULL
      }
  })
  
  # temp
  temperature <- reactive({
    req(input$temperature)
      input$temperature
  })
  
  # max token lenght
  maximum_length <- reactive({
    req(input$max_length)
    input$max_length
  })
  
#project_file_path <- sidepanel_inputs_server("sidepanel_module",volumes = volumes)  
#sidepanel_inputs_server("sidepanel_inputs",volumes = volumes)

covariates <- ace_editor_server("ace_editor", project_file_path = project_file_path)

simulation_results <- chat_bot_server(
  id = "chat_bot",
  initial_system_prompt = initial_system_prompt,
  model_choice = model_choice,
  EMBEDDING_IO_API_KEY =  Sys.getenv("EMBEDDING_IO_API_KEY"),
  COLLECTION_ID <- "col_yWQYjbDkzwX6ZD",
  PINECONE_API_KEY=Sys.getenv("PINECONE_API_KEY"),
  OPENAI_API_KEY =Sys.getenv("OPENAI_API_KEY")
)


}

shinyApp(ui = ui, server = server)