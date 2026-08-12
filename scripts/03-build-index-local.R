library(ragnar)
library(duckdb)

chunks <- markdown_chunk(
  dir = "shiny-app-pkgs",
  pattern = "\\.qmd$"
)

embedded <- embed_ollama(
  chunks,
  base_url = "http://localhost:11434",
  model = "nomic-embed-text"
)

store <- ragnar_store_create(
  embedded,
  path = "shiny-book-local.duckdb"
)
