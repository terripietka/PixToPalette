img_clusters <- function(image_df, color_num) {
  # Ensure there are enough distinct data points
  if (nrow(unique(image_df)) < color_num) {
    stop("More cluster centers than distinct data points.")
  }

  # Set seed for reproducibility
  set.seed(42)

  # Apply k-means clustering
  kmeans_result <- kmeans(image_df, centers = color_num, nstart = 20)

  # Extract cluster centers
  centers_original <- kmeans_result$centers

  # Convert cluster centers to hex colors
  hex_colors <- apply(centers_original, 1, function(row) {
    rgb(row[1], row[2], row[3], maxColorValue = 1)
  })

  # Create data frame for plotting and saving
  plot_data <- data.frame(
    x = 1:color_num,                      # Cluster numbers
    y = 1,                        # Constant height for bars
    hex_colors = hex_colors       # Hex color values
  )

  return(plot_data)
}
