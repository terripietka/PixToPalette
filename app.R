library(shiny)
library(png)
library(jpeg)
library(ggplot2)
library(base64enc)
library(magick)
library(shinycssloaders)
library(dplyr)
library(imager)

source("./library/image_processing.R")
source("./library/image_clusters.R")
source("./library/palette_viz.R")

# Define UI for application
ui <- fluidPage(
  theme = shinythemes::shinytheme("spacelab"),
  # Sidebar for file upload and number of colors
  sidebarLayout(
    sidebarPanel(
      # Application logo
      tags$img(src = "PixToPalette.png", style = "max-width: 100%; max-height: 300px; width: auto; height: auto;"),
      tags$br(),
      tags$br(),
      tags$br(),
      fileInput("image", "Upload Image (PNG or JPG)",
                accept = c("image/png", "image/jpeg")),
      numericInput("num_colors", "Number of Colors:", value = 5, min = 2, max = 20)
    ),

    # Main panel to display image and palette
    mainPanel(
      h4("Uploaded Image"),
      uiOutput("image_display"),
      h4("Palette"),
      withSpinner(plotOutput("palette_plot")),
      h4("Hex Codes"),
      verbatimTextOutput("hex_codes"),
      downloadButton("download_hex", "Download Hex Codes")
    )
  )
)

# Define server logic
server <- function(input, output, session) {

  # Display the uploaded image
  output$image_display <- renderUI({
    if (is.null(input$image)) {
      return(tags$div("Upload an image to see it displayed here!", style = "color: gray;"))
    }

    file_path <- input$image$datapath
    ext <- tolower(tools::file_ext(file_path))

    # Encode the image to base64
    base64 <- if (ext == "png") {
      base64enc::dataURI(file = file_path, mime = "image/png")
    } else if (ext == "jpg" || ext == "jpeg") {
      base64enc::dataURI(file = file_path, mime = "image/jpeg")
    } else {
      stop("Unsupported file format. Please upload a PNG or JPG file.")
    }

    # Return the HTML for the image
    tags$img(src = base64, style = "max-width: 100%; max-height: 300px; width: auto; height: auto;")

  })

  # Read and process the image
  image_data <- reactive({
    req(input$image)
    image_to_df(input$image$datapath)
  })

  # Reactive expression to perform k-means clustering
  palette_data <- reactive({
    req(image_data())
    img_clusters(image_data(), input$num_colors)
  })

  # Dynamically update the max value for num_colors based on unique colors
  observeEvent(image_data(), {
    max_colors <- nrow(unique(image_data()))
    updateNumericInput(session, "num_colors", max = max_colors)
  })

  # Display the palette plot
  output$palette_plot <- renderPlot({
    req(palette_data())
    validate(
      need(nrow(palette_data()) > 0, "No colors could be extracted from the image.")
    )
    palette_viz(palette_data())
  })

  # Display hex codes
  output$hex_codes <- renderText({
    req(palette_data())
    paste(palette_data()$hex_colors, collapse = "\n")
  })

  # Allow hex codes to be downloaded as a text file
  output$download_hex <- downloadHandler(
    filename = function() {
      paste("palette_hex_codes", Sys.Date(), ".txt", sep = "")
    },
    content = function(file) {
      req(palette_data())
      writeLines(palette_data()$hex_colors, file)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)


