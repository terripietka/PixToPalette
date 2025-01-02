library(imager)

library(imager)

image_to_df <- function(image_file, max_dim = 500, sample_fraction = 1) {
  # Check if the file exists
  if (!file.exists(image_file)) {
    stop("File does not exist. Please provide a valid file path.")
  }

  # Load the image
  image <- load.image(image_file)

  # Get current dimensions of the image
  width <- dim(image)[1]
  height <- dim(image)[2]

  # Calculate resize ratio based on max_dim
  resize_ratio <- min(max_dim / width, max_dim / height, 1)

  # Resize the image if it exceeds max dimensions
  if (resize_ratio < 1) {
    image <- imresize(image, resize_ratio)
  }

  # Convert to data frame with RGB values
  image_RGB <- as.data.frame(image, wide = "c") %>%
    rename(R = c.1, G = c.2, B = c.3) %>%
    mutate(hexvalue = rgb(R / 255, G / 255, B / 255))

  # Sample a fraction of the pixels if sample_fraction < 1
  if (sample_fraction < 1) {
    image_RGB <- image_RGB %>%
      sample_frac(sample_fraction)
  }

  # Remove any rows with NA values
  image_df <- na.omit(image_RGB)

  return(image_df)
}


