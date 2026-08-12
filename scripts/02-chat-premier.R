library(ragnar)
library(duckdb)

store <- ragnar_store_open("shiny-book-index.duckdb")

chat <- ragnar_chat_create(
  store = store,
  model = "claude-3-5-sonnet-20241022",
  provider = "anthropic"
)

response <- ragnar_chat_message(
  chat,
  "How do I structure file names for R6 class modules in a Shiny app-package?"
)

cat(response$answer)
cat("\n\nSources:\n")
print(response$sources)
