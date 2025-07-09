chat_bot_server <- function(
    id,
    initial_system_prompt,
    model_choice,
    EMBEDDING_IO_API_KEY,
    COLLECTION_ID,
    PINECONE_API_KEY,
    OPENAI_API_KEY
) {
  moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
    
    # Hide chat_ui initially
    shinyjs::hide(id = "chat_box")
    shinyjs::hide(id = "robot_emoji_box")
    shinyjs::hide(id = "run_button_box")
    
    observeEvent(input$wake_up, {
      if (input$wake_up) {
        shinyjs::show(id = "chat_box")
        shinyjs::show(id = "robot_emoji_box")
      } else {
        shinyjs::hide(id = "chat_box")
        shinyjs::show(id = "robot_emoji_box")
      }
    })
    
    output$robot_emoji <- renderText({
      req(input$wake_up)
      "🤖 Simulx Bot is awake!
       I'm ready to help build simulations
      "
    })
    
    # Reactive values
    generated_text <- reactiveVal()
    generated_code <- reactiveVal()
    simulation_results <- reactiveVal()
    
    # Initialize Chatbot- bootup prompt 
    chat <- reactive({
      ellmer::chat_openai(
        model = model_choice(),  
        system_prompt = initial_system_prompt
      )
    })
    
    # # Safe evaluation function
    # safe_eval <- function(code_string) {
    #   tryCatch({
    #     expr <- parse(text = code_string)
    #     result <- eval(expr)
    #     if (!is.null(result)) {
    #       return(result)
    #     } else {
    #       warning("Generated code did not return a valid plot.")
    #       NULL
    #     }
    #   }, error = function(e) {
    #     warning("Error evaluating generated R code: ", e$message)
    #     NULL
    #   })
    # }
    
    observeEvent(input$chat_simulx_user_input, {
      
      req(input$wake_up)
      req(input$chat_simulx_user_input)
      
      user_input <- input$chat_simulx_user_input
      
      # Embedding.io documents related to query
      docs <- tryCatch(
        {
          # Retrieve the docs
          retrieved_docs <- retrieve_docs(
            query = user_input,
            EMBEDDING_IO_API_KEY = EMBEDDING_IO_API_KEY,
            COLLECTION_ID = COLLECTION_ID
          )
          
          # Print a success message
          message("lixoftconectors function docs retrieved")
          
          # Return the retrieved docs
          retrieved_docs
        },
        error = function(e) {
          # Log the error message
          message("Error retrieving embedding.io information: ", e$message)
          ""
        }
      )
      
      # Debugging: Check if docs were retrieved
      if (is.null(docs) || docs == "") {
        message("No valid docs retrieved.")
      } else {
        message("Docs retrieved successfully.")
      }

# get open ai embedding ---------------------------------------------------

      
      # Get OpenAI embeddings
      open_ai_embeddings <- tryCatch(
        {
          # Call the function to get OpenAI embeddings
          embeddings_result <- get_open_ai_embeddings(
            query = user_input,
            OPENAI_API_KEY = OPENAI_API_KEY
          )
          
          # Validate the result
          if (is.null(embeddings_result) || length(embeddings_result) == 0) {
            message("Warning: OpenAI embeddings returned an empty result.")
            return("")  # Return an empty string if result is invalid
          }
          
          # Print the embeddings to the console for verification
          message("OpenAI embeddings successful")
          
          
          # Return the valid embeddings
          embeddings_result
        },
        error = function(e) {
          # Log the error message
          message("Error getting OpenAI embeddings: ", e$message)
          return("")  # Return an empty string in case of error
        },
        warning = function(w) {
          # Handle warnings gracefully, if needed
          message("Warning during OpenAI embeddings query: ", w$message)
          invokeRestart("muffleWarning")  # Suppress the warning
          return("")  # Optionally return an empty string
        }
      )

# get pinecone ------------------------------------------------------------

      # Query Pinecone if embeddings are valid
      if (!is.null(open_ai_embeddings) && length(open_ai_embeddings) > 0) {
        pinecone_results <- tryCatch(
          query_pinecone(
            query_embedding = open_ai_embeddings,
            top_k = 1,
            PINECONE_API_KEY = PINECONE_API_KEY
          ),
          error = function(e) {
            message("Error querying Pinecone: ", e$message)
            return("")
          }
        )
        
        if (is.null(pinecone_results) || pinecone_results == "") {
          message("Warning: Pinecone query returned an empty result.")
        } else {
          message("Query results from Pinecone retrieved.")
        }
      } else {
        message("OpenAI embeddings are invalid; skipping Pinecone query.")
        pinecone_results <- ""
      }
      
# Combine prompts, send to llm --------------------------------------------

      
      user_prompt_and_docs <- paste(
        "Here is some additional info from lixoft websites:", docs,
        "Here is some additional R code documentation from lixoft connectors package", pinecone_results,
        "\n Using the additional info and general knowledge please Generate R code for:",
        user_input 
      )
      
      chat_obj <- chat()
      
      # Async ellmer call
      future <- chat_obj$chat_async(user_prompt_and_docs)
      
      # When done...
      future %...>% (function(response) {
        # Split text and code block
        parts <- strsplit(response, "R code response:")[[1]]
        explanation <- trimws(parts[1])
        code <- NULL
        
        if (length(parts) >= 2) {
          code <- sub("^```R\\s*|\\s*```$", "", trimws(parts[2]))
        }
        
        # Add explanation to chat
        chat_append("chat_simulx", explanation)
        
        # Show code panel (with code highlight, copy, run)
        if (!is.null(code) && nzchar(code)) {
          generated_code(code) # update the UI panel
        } else {
          generated_code("")   # clear if no code found
        }
      })
    })
      
  
      observe({
      
      req(isTruthy(generated_code()))
      
      code <- generated_code()
      if (!nzchar(code)) return(NULL)  # empty panel if no code
      updateAceEditor(session, "code_panel", value = code)
      
      # Validate the code for required strings
      is_valid <- !is.null(code) &&
        grepl("exportProject", code, fixed = TRUE) &&
        grepl("runSimulation", code, fixed = TRUE)
      
      # Show or hide the button based on validation
        req(is_valid)
        shinyjs::show("run_button_box")
  
    })
      
    
      observeEvent(input$run_button, {
        
        code <- generated_code()
        
        code <- str_replace(code,"```r",replacement = "#")
        code <- str_replace_all(code,"```",replacement = "#")
        
        
        
        # Try to evaluate the code
        result <- eval(parse(text = code), envir = .GlobalEnv)
       
        req(result)
        valid_result <- eval(parse(text ="getSimulationResults()"), envir = .GlobalEnv) 
    
        
        # Store the result 
        simulation_results(valid_result)
        
      })
      
   
        return(simulation_results)
  
      
      
      
  })
}