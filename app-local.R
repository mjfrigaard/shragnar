library(shiny)
library(bslib)
library(ragnar)
library(duckdb)

store <- ragnar_store_open("shiny-book-local.duckdb")

ui <- page_fillable(
  title = "Shiny App-Packages Chatbot",
  layout_columns(
    col_widths = 12,
    card(
      full_screen = TRUE,
      card_header("Chat"),
      card_body(
        uiOutput("history"),
        style = "overflow-y: auto;"
      ),
      card_footer(
        layout_columns(
          col_widths = c(10, 2),
          textAreaInput("question", label = NULL, placeholder = "Ask a question...", width = "100%"),
          actionButton("ask", "Send", class = "btn-primary")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  chat <- ragnar_chat_create(
    store = store,
    model = "mistral",
    provider = "ollama",
    base_url = "http://localhost:11434"
  )

  messages <- reactiveVal(list())

  observeEvent(input$ask, {
    req(input$question)

    response <- ragnar_chat_message(chat, input$question)

    messages(c(
      messages(),
      list(list(role = "user", text = input$question)),
      list(list(role = "assistant", text = response$answer))
    ))

    updateTextAreaInput(session, "question", value = "")
  })

  output$history <- renderUI({
    tagList(lapply(messages(), function(m) {
      label <- if (m$role == "user") "You" else "Assistant"
      div(
        class = if (m$role == "user") "text-end mb-2" else "text-start mb-2",
        strong(label), ": ", m$text
      )
    }))
  })
}

shinyApp(ui, server)
