library(shiny)
library(png)
library(jpeg)
library(ggplot2)
library(base64enc)
library(magick)
library(shinycssloaders)
library(dplyr)
library(imager)
library(pryr)  # For memory usage logging

source("./library/image_processing.R")
source("./library/image_clusters.R")
source("./library/palette_viz.R")

# Set maximum file upload size (e.g., 50 MB)
options(shiny.maxRequestSize = 50 * 1024^2)

# Define UI for application
ui <- fluidPage(
  theme = shinythemes::shinytheme("spacelab"),
  sidebarLayout(
    sidebarPanel(
      tags$img(src = "PixToPalette.png", style = "max-width: 100%; max-height: 300px; width: auto; height: auto;"),
      tags$br(),
      tags$br(),
      tags$br(),
      fileInput("image", "Upload Image (PNG or JPG)", accept = c("image/png", "image/jpeg")),
      numericInput("num_colors", "Number of Colors:", value = 5, min = 2, max = 20)
    ),
    mainPanel(
      h4("Uploaded Image"),
      uiOutput("image_display"),
      h4("Palette"),
      withSpinner(plotOutput("palette_plot")),
      h4("Hex Codes"),
      verbatimTextOutput("hex_codes"),
      downloadButton("download_hex", "Download Hex Codes"),
      capture::capture_pdf(
        selector = "body",
        filename = "palette.pdf",
        icon("download", "Download PDF"), "Download PDF of results"
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  cat("Server started. Listening for file uploads...\n")

  # Display the uploaded image
  output$image_display <- renderUI({
    if (is.null(input$image)) {
      return(tags$div("Upload an image to see it displayed here!", style = "color: gray;"))
    }

    file_path <- input$image$datapath
    ext <- tolower(tools::file_ext(file_path))

    cat("File uploaded:", input$image$name, "\n")
    cat("File path:", file_path, "\n")
    cat("File extension:", ext, "\n")

    # Resize the image using magick
    img <- magick::image_read(file_path)
    img <- magick::image_scale(img, "1024x1024")  # Resize to max 1024x1024 pixels

    # Save the resized image to a temporary file
    temp_file <- tempfile(fileext = ".png")
    magick::image_write(img, path = temp_file, format = "png")
    cat("Resized image saved to:", temp_file, "\n")

    # Encode the resized image to base64
    base64 <- tryCatch({
      base64enc::dataURI(file = temp_file, mime = "image/png")
    }, error = function(e) {
      cat("Error during base64 encoding:", e$message, "\n")
      return(NULL)
    })

    if (is.null(base64)) {
      return(tags$div("The uploaded image could not be displayed. Please check the file format or size.", style = "color: red;"))
    }

    # Return the HTML for the resized image
    tags$img(src = base64, style = "display: block; margin-left: auto; margin-right: auto; max-width: 100%; max-height: 300px; width: auto; height: auto;")
  })

  # Read and process the image
  image_data <- reactive({
    req(input$image)
    file_path <- input$image$datapath
    cat("Memory before processing:", mem_used(), "\n")

    # Read and resize the image using magick
    img <- magick::image_read(file_path)
    img <- magick::image_scale(img, "1024x1024")  # Resize to max 1024x1024 pixels

    # Save the resized image to a temporary file
    temp_file <- tempfile(fileext = ".png")
    magick::image_write(img, path = temp_file, format = "png")
    cat("Resized image saved to:", temp_file, "\n")

    # Pass the temporary file to image_to_df
    img_data <- tryCatch({
      image_to_df(temp_file)  # Ensure temp_file is passed as the file path
    }, error = function(e) {
      cat("Error in image_to_df:", e$message, "\n")
      NULL
    })

    if (is.null(img_data)) {
      stop("Error: Unable to process image data.")
    }

    cat("Memory after processing:", mem_used(), "\n")
    return(img_data)
  })

  # Reactive expression to perform k-means clustering
  palette_data <- reactive({
    req(image_data())
    cat("Clustering colors...\n")
    tryCatch({
      img_clusters(image_data(), input$num_colors)
    }, error = function(e) {
      cat("Error in img_clusters:", e$message, "\n")
      NULL
    })
  })

  # Dynamically update the max value for num_colors based on unique colors
  observeEvent(image_data(), {
    max_colors <- nrow(unique(image_data()))
    cat("Setting max number of colors to:", max_colors, "\n")
    updateNumericInput(session, "num_colors", max = max_colors)
  })

  # Display the palette plot
  output$palette_plot <- renderPlot({
    req(palette_data())
    validate(
      need(nrow(palette_data()) > 0, "No colors could be extracted from the image.")
    )
    cat("Generating palette plot...\n")
    palette_viz(palette_data())
  })

  # Display hex codes
  output$hex_codes <- renderText({
    req(palette_data())
    cat("Displaying hex codes...\n")
    paste(palette_data()$hex_colors, collapse = "\n")
  })

  # Allow hex codes to be downloaded as a text file
  output$download_hex <- downloadHandler(
    filename = function() {
      paste("palette_hex_codes", Sys.Date(), ".txt", sep = "")
    },
    content = function(file) {
      req(palette_data())
      cat("Preparing hex codes for download...\n")
      writeLines(palette_data()$hex_colors, file)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)

