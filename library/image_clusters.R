img_clusters <- function(image_df, color_num) {
  # Set seed for reproducibility
  set.seed(42)

  # Apply k-means clustering
  kmeans_result <- kmeans(image_df[, c("R", "G", "B")], centers = color_num, nstart = 20)

  # Add cluster assignments to the data frame
  image_df$cluster_num <- kmeans_result$cluster

  # Extract cluster centers and map them to hex colors
  centers_original <- kmeans_result$centers %>%
    as.data.frame() %>%
    mutate(
      group_hex = rgb(R, G, B),
      cluster_num = row_number()
    )

  # Join cluster counts
  centers_original <- centers_original %>%
    inner_join(image_df %>% count(cluster_num), by = "cluster_num")

  # Convert cluster centers to hex colors
  hex_colors <- centers_original$group_hex

  # Create data frame for plotting
  plot_data <- centers_original %>%
    mutate(
      x = cluster_num,          # Sequential numbering
      y = 1,                    # Constant value for bar height
      hex_colors = group_hex    # Map group_hex to hex_colors
    ) %>%
    select(x, y, hex_colors, group_hex, cluster_num)  # Ensure all columns are included

  print(head(plot_data))  # Debug output

  return(plot_data)
}


