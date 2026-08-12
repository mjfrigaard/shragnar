library(ragnar)
library(duckdb)

store <- ragnar_store_open("shiny-book-local.duckdb")

chat <- ragnar_chat_create(
  store = store,
  model = "mistral",
  provider = "ollama",
  base_url = "http://localhost:11434"
)

response <- ragnar_chat_message(
  chat,
  "Explain the difference between module-based and R6-based architecture in Shiny app-packages."
)

cat(response$answer)
