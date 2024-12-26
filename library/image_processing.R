#### function to convert image pixel data to dataframe ####

#### function to convert image pixel data to dataframe ####

library(png)
library(jpeg)
library(magick)

image_to_df <- function(image_file) {
  # Check if the file exists
  if (!file.exists(image_file)) {
    stop("File does not exist. Please provide a valid file path.")
  }

  # Determine file type by extension
  file_extension <- tools::file_ext(image_file)

  # Read and resize the image
  if (tolower(file_extension) == "png" || tolower(file_extension) == "jpg" || tolower(file_extension) == "jpeg") {
    image <- image_read(image_file)
    image <- image_scale(image, "300")
    image <- as.raster(image)
  } else {
    stop("Unsupported file format. Please use a PNG or JPG file.")
  }

  # Convert the image to a matrix and then to a data frame
  image_matrix <- as.matrix(image)
  image_df <- data.frame(
    Red = as.numeric(image_matrix[, , 1]),
    Green = as.numeric(image_matrix[, , 2]),
    Blue = as.numeric(image_matrix[, , 3])
  )

  # Remove any rows with NA values
  image_df <- na.omit(image_df)

  return(image_df)
}
