#### Plot the identified colors ####

palette_viz <- function(plot_data) {
  # Ensure required columns exist
  if (!all(c("x", "y", "hex_colors") %in% colnames(plot_data))) {
    stop("plot_data must include 'x', 'y', and 'hex_colors' columns.")
  }

  # Create the ggplot
  p <- ggplot(data = plot_data, aes(x = factor(x), y = y, fill = hex_colors)) +
    geom_bar(stat = "identity") +  # Create bars with constant height
    scale_fill_identity() +        # Use hex colors directly
    theme_minimal() +              # Use a minimal theme
    theme(
      legend.position = "none",               # Remove legend
      axis.title = element_blank(),           # Remove axis titles
      axis.text = element_blank(),            # Remove axis tick labels
      axis.ticks = element_blank(),           # Remove axis ticks
      panel.grid = element_blank()            # Remove grid lines
    ) +
    labs(title = "Palette Colors") +
    geom_text(aes(label = hex_colors), vjust = -1)  # Add hex color labels above bars

  # Return the ggplot object
  return(p)
}

