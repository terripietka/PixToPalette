palette_viz <- function(plot_data) {
  # Ensure required columns exist
  required_columns <- c("x", "y", "hex_colors", "group_hex", "cluster_num")
  if (!all(required_columns %in% colnames(plot_data))) {
    stop("plot_data must include 'x', 'y', 'hex_colors', 'group_hex', and 'cluster_num' columns.")
  }

  # Determine the number of rows for the tile layout
  num_colors <- nrow(plot_data)
  num_rows <- ceiling(num_colors / 5)  # Divide colors into rows of 5

  # Adjust x and y for a grid layout
  plot_data <- plot_data %>%
    mutate(
      x = (row_number() - 1) %% 5 + 1,  # Columns cycle from 1 to 5
      y = num_rows - ((row_number() - 1) %/% 5)  # Rows decrease from top to bottom
    )

  # Create the ggplot
  p <- ggplot(data = plot_data, aes(x = x, y = y)) +
    geom_tile(aes(fill = hex_colors), color = "white", linewidth = 0.5) +  # Tiles with borders
    geom_label(
      aes(label = paste(cluster_num, ":", hex_colors)),
      family = "Roboto Condensed", lineheight = 0.8, size = 6,
      color = "black", fill = "white", label.size = 0.25
    ) +
    scale_fill_identity() +  # Use hex colors directly
    theme_void() +  # Remove axis ticks, labels, and background
    theme(
      panel.grid = element_blank(),  # Remove grid lines
      plot.title = element_text(hjust = 0.5, family = "Roboto Condensed", size = 14)
    ) +
    labs(title = "Palette Colors")

  return(p)
}



