chat_bot_ui <- function(id) {
 
 ns <- NS(id)
  
 fluidPage(
   titlePanel("Simulx Bot"),
   # Use bslib's layout with two columns and cards
   bslib::layout_columns(
     # Left column
       bslib::card(
         title = "Simulx Bot Controls",
         shiny::checkboxInput(ns("wake_up"), "Wake up Simulx Bot", value = FALSE),
         div(id = ns("robot_emoji_box"),
             textOutput(ns("robot_emoji"))
         ),
         div(id = ns("chat_box"),  # Wrap chat_ui in a div
             chat_ui(ns("chat_simulx"))
         )
       ),
     # Right column
       bslib::card(
         title = "R Code Panel",
         #shinyjs::hidden(actionButton(ns("run_button"), "Run Simulation")),
         div(id = ns("run_button_box"),
             actionButton(ns("run_button"), "Run Simulation")
             ),
         aceEditor(ns("code_panel"), value = "", mode = "r", theme = "chrome",
                   wordWrap = TRUE,
                   readOnly = FALSE, height = "650px", fontSize = 14,
                   showLineNumbers = TRUE, highlightActiveLine = FALSE)
       )
     )
 )
}
