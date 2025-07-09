sidepanel_inputs_ui <- function(id) {

  ns <- NS(id)
 
  tagList(
    selectInput(ns("model_name"), "Model Name",
                choices = c("gpt-4o-mini", "chatgpt-4o-latest",
                            "gpt-3.5-turbo-0125", 
                            "gpt-3.5-turbo"), 
                selected = "gpt-3.5-turbo"),
    accordion(id = ns("accordion_sidepanel"),
              open = FALSE,
              accordion_panel(
                title = "Query Controls",  
                sliderInput(ns("temperature"), "Temperature", min = 0.1, max = 1.0, value = 0.7, step = 0.1),
                sliderInput(ns("max_length"), "Maximum Length", min = 1, max = 2048, value = 1500, step = 1)
              ))
    )
}   