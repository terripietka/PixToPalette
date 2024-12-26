library(shiny)
library(png)
library(jpeg)
library(ggplot2)
library(base64enc)
library(magick)

source("./library/image_processing.R")
source("./library/image_clusters.R")
source("./library/palette_viz.R")

# Define UI for application
ui <- fluidPage(

  # Application title
  titlePanel("Pix to Palette Generator"),

  # Sidebar for file upload and number of colors
  sidebarLayout(
    sidebarPanel(
      fileInput("image", "Upload Image (PNG or JPG)",
                accept = c("image/png", "image/jpeg")),
      numericInput("num_colors", "Number of Colors:", value = 5, min = 2, max = 20)
    ),

    # Main panel to display image and palette
    mainPanel(
      h4("Uploaded Image"),
      uiOutput("image_display"),
      h4("Palette"),
      plotOutput("palette_plot"),
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
    req(input$image)

    file_path <- input$image$datapath
    ext <- tools::file_ext(file_path)

    # Encode the image to base64
    base64 <- if (tolower(ext) == "png") {
      base64enc::dataURI(file = file_path, mime = "image/png")
    } else if (tolower(ext) == "jpg" || tolower(ext) == "jpeg") {
      base64enc::dataURI(file = file_path, mime = "image/jpeg")
    } else {
      stop("Unsupported file format. Please upload a PNG or JPG file.")
    }

    # Return the HTML for the image
    tags$img(src = base64, width = 500)
  })

    # read and process the image
  image_data <- reactive({
    req(input$image)
    image_to_df(input$image$datapath)
  })

     # Reactive expression to perform k-means clustering
  palette_data <- reactive({
    req(image_data())
    img_clusters(image_data(), input$num_colors)
  })

    # Display the palette plot
  output$palette_plot <- reactive({
    req(palette_data())
    palette_viz(palette_data())
  })

  # Display hex codes
  output$hex_codes <- renderText({
    req(palette_data())
    paste(palette_data()$Hex, collapse = "\n")
  })

  # Allow hex codes to be downloaded as a text file
  output$download_hex <- downloadHandler(
    filename = function() {
      paste("palette_hex_codes", Sys.Date(), ".txt", sep = "")
    },
    content = function(file) {
      req(palette_data())
      writeLines(palette_data()$Hex, file)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)

