
# embeddings.io api  ------------------------------------------------------

# Queries websites 
retrieve_docs <- function(query,EMBEDDING_IO_API_KEY,COLLECTION_ID) {
  
  if (nchar(EMBEDDING_IO_API_KEY)<=1) {
    cli::cli_abort("invalid embedding.io api key ")
  }
     
  req <- request("https://api.embedding.io/v0/query")
  # print(paste0("Bearer ", EMBEDDING_IO_API_KEY))
  
  req <- req |>
    req_headers(
      "Authorization" = paste0("Bearer ", EMBEDDING_IO_API_KEY)
    ) |>
    req_body_json(list(
      "collection" = COLLECTION_ID,
      "query" = query
    ))
  
  req |> req_dry_run()
  
  response <- req_perform(req)
  
  # Parse the response as JSON and extract the relevant documents
  content <- resp_body_json(response)
  
  
  # remove garbage text like long urls,
  # pick highest 3 scores (most relevant) 
  a <- content %>%
    map_dfr(~ .x[c("score","content")]) %>%
    arrange(desc(score)) %>%
    mutate(content=gsub("\\n\\[.*", "",content),
           content=gsub("\\[.*?\\]\\(.*?\\)", "",content)
    ) %>%
    slice(1:3)
  
  b <-  paste(a$content, collapse = "\n")
  
  # all_item_contents <- lapply(content, function(item) {
  #   return(item$content)
  # })
  # 
  # retrieved_docs <- paste(all_item_contents, collapse = "\n\n")
  # return(retrieved_docs)
  
  return(b)
  
}

# Retrieve pinecone

# open ai api ebeddings ---------------------------------------------------

# gets the user query ready for pinecone

get_open_ai_embeddings <- function(query,OPENAI_API_KEY) {
  
  if (nchar(OPENAI_API_KEY)<=1) {
    cli::cli_abort("invalid open AI api key ")
  }
  
  open_ai_request <- request("https://api.openai.com/v1/embeddings")
  
  open_ai_request <- open_ai_request %>%
    req_headers("Authorization" = paste0("Bearer ", OPENAI_API_KEY),
                "Content-Type" = "application/json") %>%
    req_body_json(list("model" = "text-embedding-ada-002",
                       "input" = query))
  
  open_ai_request %>%
    req_dry_run()
  
  response <- req_perform(open_ai_request)
  
  content <- resp_body_json(response)
  
  if (!is.null(content$error)) {
    cli::cli_abort("Error sending request to open AI embeddings")
  }
  
  # Extract the embedding from the response
  embedding <- content$data[[1]]$embedding
  
  embedding <- unlist(embedding)
  
  # Check if embedding is valid (it should be a numeric vector of floats)
  if (is.null(embedding) || !is.numeric(embedding)) {
    cli::cli_abort("Invalid embedding returned from OpenAI")
  }
  
  # Ensure the embedding is a numeric vector (flattened)
  embedding <- as.numeric(embedding)  # Convert to numeric if it's not already
  
  # Check the length of the embedding (it should match the expected dimension for your Pinecone index, e.g., 1536)
  embedding_length <- length(embedding)
  cat("Embedding length: ", embedding_length, "\n")  # Debugging step
  
  if (embedding_length != 1536) {
    cli::cli_abort(paste("Embedding length mismatch: Expected 1536, got", embedding_length))
  }
  
  # Return the numeric embedding vector that can be passed to Pinecone
  return(embedding)
}

# pinecone query ----------------------------------------------------------
# 



# test_embeddings <- get_open_ai_embeddings("what is washout")

query_pinecone <- function(query_embedding,top_k = 1,PINECONE_API_KEY){
  
  if (nchar(PINECONE_API_KEY)<=1) {
    cli::cli_abort("invalid pinecone api key ")
  }
  
  
  # length should be exactly 1536. Update test later
  if (length(query_embedding)<=1) {
    cli::cli_abort("Invalid embedding length. Check output from {.fun get_open_ai_embeddings}")
  }
  
  if (!class(query_embedding)=="numeric") {
    cli::cli_abort("Invalid embedding. Must be numeric not {{class(query_embedding)}}")
  }
  
  #embedding_vector <- query_embedding$data[[1]]$embedding
  # Ensure it is a numeric vector
  embedding_vector <- unlist(query_embedding)
  
  # this will change based on vector database name now is "shiny-bot-index2"
  query_url <- "https://shiny-bot-index2-eb322ca.svc.aped-4627-b74a.pinecone.io/query"
  
  pinecone_request <- request(query_url)
  
  pinecone_request <- pinecone_request %>%
    req_headers("Api-Key" = PINECONE_API_KEY,
                "Content-Type" = "application/json") %>%
    req_body_json(list(
      "vector" =  embedding_vector,
      "index" = "shiny-bot-index2",
      "top_k" = 3,
      "include_metadata"=TRUE
    ))
  
  # just for debugging 
  
  # pinecone_request %>%
  # req_dry_run()
  
  response <- req_perform(pinecone_request)
  
  content <- resp_body_json(response)
  
  if (!is.null(content$error)) {
    cli::cli_abort("Error sending request to pinecone")
  }
  
  
  # look at "a" to see the scores
  a <- content %>%
    pluck("matches") %>%
    map_dfr(~tibble(score=.x$score,
                    text= str_replace_all(.x$metadata$text,"\\\\n","\n")))
  
  b <- paste(a$text, collapse = "\n")
  
  
  return(b)
  
}
