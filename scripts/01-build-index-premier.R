library(ragnar)
library(duckdb)

book_path <- "shiny-app-pkgs"

chunks <- markdown_chunk(
  dir = book_path,
  pattern = "\\.qmd$"
)

embedded <- embed_anthropic(
  chunks,
  model = "claude-3-5-sonnet-20241022"
)

store <- ragnar_store_create(
  embedded,
  path = "shiny-book-index.duckdb"
)
