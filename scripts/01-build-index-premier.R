# install.packages(c("ragnar", "duckdb"))

library(ragnar)
library(duckdb)

book_path <- "book/shiny-app-pkgs-main"

# Files starting with _ are Quarto partials (not chapter content); excluded by pattern
qmd_paths <- list.files(book_path, pattern = "^[^_].*\\.qmd$", full.names = TRUE)

chunks <- lapply(qmd_paths, \(path) markdown_chunk(read_as_markdown(path))) |>
  dplyr::bind_rows()

# confirm structure
str(chunks)

embedded <- embed_ollama(chunks, model = "nomic-embed-text")

store <- ragnar_store_create(
  embedded,
  path = "shiny-book-index.duckdb"
)
