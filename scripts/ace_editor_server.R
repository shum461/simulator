# Ace Editor Server Module

ace_editor_server <- function(id, project_file_path) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns  # Namespacing function for IDs
    
    
    covariates <- reactiveVal()
    
    # Load and update file content when project_file_path changes
    observeEvent(
      project_file_path(), {
      req(project_file_path())  # Ensure the project file path is available
      req(file.exists(project_file_path()$datapath))  # Ensure the file exists
      
      # if someone ran a simulation then switches projects, need to use monolix again
      lixoftConnectors::initializeLixoftConnectors(
        software = "monolix",
        path = "/srv/Lixoft/MonolixSuite2024R1/",
        force = TRUE)
      
      # Read and display file content in Ace Editor
      content <- tryCatch({
        readLines(project_file_path()$datapath)
      }, error = function(e) {
        message("Error reading file content: ", e$message)
        NULL
      })
     
       if (!is.null(content)) {
       shinyAce::updateAceEditor(session, 'file_contents', value = paste(content, collapse = "\n"))
       
         
      header_line <- grep("header =", content, value = TRUE) 
      header_content <- gsub(".*header = \\{([^}]*)\\}.*", "\\1", header_line)
        
       covariates(header_content)
        
       print(header_content)

        }
      
      
      # Load the Monolix project file
      model_project <- tryCatch({
        #result <- loadProject(project_file_path()$datapath)
        #result
        loadProject(project_file_path()$datapath)
        
      }, error = function(e) {
        message("Error loading model project: ", e$message)
        NULL
      })
      
      print(getProjectSettings())
      

      # Load the model content
      model <- tryCatch({
        result <- getLibraryModelContent(getStructuralModel())
        result 
      }, error = function(e) {
        message("Error loading model file: ", e$message)
        NULL
      })
      
      req(!is.null(model))  # Ensure model content is successfully loaded
      shinyAce::updateAceEditor(session, 'model_contents', value = paste(model, collapse = "\n"))
      
      req(!is.null(model))  # Ensure model content is successfully loaded
      
      output_part <- trimws(sub(".*OUTPUT:\\s*output = \\{([^}]*)\\}.*", "\\1", model))
      #covariate_part <- sub(".*\\[LONGITUDINAL\\]\\s*input = \\{([^}]*)\\}.*", "\\1", model)
      
      shinyAce::updateAceEditor(session, 'simulation_script', 
                            value = glue::glue("defineOutputElement(output = '{output_part}')")
                            )
      
      
    })
    

    
    
    return(covariates)
    
  })
}