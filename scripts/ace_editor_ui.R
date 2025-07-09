# Ace Editor UI Module

ace_editor_ui <- function(id) {
  ns <- NS(id)  # Namespace function for the module
  
  tagList(
    layout_columns(
      # First card for Monolix File
      card(
        full_screen = TRUE,
        card_header("Monolix File"),
        card_body(
          shinyAce::aceEditor(
            outputId = ns('file_contents'),  # Namespaced ID for the Ace Editor
            value = "Load a monolix file",  # Initial content of the editor
            placeholder = "",  # Placeholder text
            height = "950px"  # Height of the editor
          )
        )
      ),

      # Second card for Model
      card(
        full_screen = TRUE,
        card_header("Model"),
        card_body(
          shinyAce::aceEditor(
            outputId = ns("model_contents"),  # Namespaced ID for the Ace Editor
            value = "Model",  # Initial content of the editor
            placeholder = "",  # Placeholder text
            height = "950px"  # Height of the editor
          )
        )
      )
    ),

    # Navigation Panel for Simulation Script
    nav_panel(
      "Simulation Script",
      card_body(
        shinyAce::aceEditor(
          outputId = ns("simulation_script"),  # Namespaced ID for the simulation script editor
          value = "",  # Initial content of the editor
          placeholder = "",  # Placeholder text
          height = "950px"  # Height of the editor
        )
      )
    )
  )
}