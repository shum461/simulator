# Server logic for the sidepanel inputs module
sidepanel_inputs_server <- function(id,volumes) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns  # Namespacing function for IDs
    

    # 
    # volumes2 <- c(
    #   Demos = "/home/shummel/lixoft/monolix/monolix2024R1/demos",
    #   Home = "/home/shummel",
    #   "R Installation" = "/usr/lib/R",
    #   Computer = "/"
    # )
    # 
    # Use volumes() to evaluate the reactive
  #   observeEvent(input$shinyfilesbtn, {
  #     
  # shinyFileChoose(
  #     input,
  #     id = "shinyfilesbtn",
  #     defaultPath = '',
  #     defaultRoot = 'wd',
  #     roots = volumes2,  # Notice the () here to evaluate the reactive
  #     session = session,
  #     filetypes = NULL
  #   )
  #   
  # })
    # 
    # observeEvent(input$shinyfilesbtn, {
    #   cat("Button clicked!\n")  # Debugging button click
    #   print(input$shinyfilesbtn)  # Debug the raw input object
    #   
    #   # Parse selected file paths
    #   imported_project <- parseFilePaths(volumes2, input$shinyfilesbtn)
    #   print(imported_project)  # Debug parsed file paths
    # })
    # 
    # 
    # observeEvent(input$shinyfilesbtn, {
    #   imported_project <- parseFilePaths(volumes2, input$shinyfilesbtn)
    #   print(imported_project)
    # })
    # 
    # observe({
    #   print("my volumes")
    #   print(volumes())
    # 
    # 
    # 
    # # Reactive value to store project file path
    # project_file_path <- reactiveVal()
    # # 
    # # 
    # # 
    # # # Update project file path when a file is selected
    # observeEvent(input$shinyfilesbtn, {
    #   req(input$shinyfilesbtn)
    #   imported_project <- parseFilePaths(volumes2, input$shinyfilesbtn)
    #   project_file_path(imported_project)
    # })
    # # 
    # # 
    # # 
    # # # Render table output for file paths
    # # output$filepaths <- renderTable({
    # #   req(input$shinyfilesbtn)
    # #   project_file_path()$name
    # # })
    # # 
    # # # Render text output for file name
    # # output$filename <- renderText({
    # #   req(input$shinyfilesbtn)
    # #   project_file_path()$name 
    # #   })
    #   
    #   return(project_file_path)
    # 
  })
}