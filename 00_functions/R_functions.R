# Shared palette, also used explicitly in the figure scripts.
Dark2 = c("#56B4E9", "#D95F02FF", "#7570B3FF", "#E7298AFF",
          "#66A61EFF", "#E6AB02FF", "#A6761DFF", "#666666FF")

# Reset to theme_gray(), then set the global theme and default discrete colours.
# Defaults match the manuscript; individual scripts can override them.
set_plot_theme = function(
    title_size = 30,
    axis_text_size = 18,
    axis_title_size = 18,
    strip_text_size = 20,
    axis_title_x_margin = ggplot2::margin(0, 0, 10, 0),
    legend_position = "bottom",
    legend_text_size = 17,
    legend_title_size = 19,
    legend_key_height = 0.6,
    strip_text_x_size = NULL,
    strip_text_y_size = 20,
    panel_spacing = 1.4
) {
    ggplot2::theme_set(ggplot2::theme_gray())

    theme_elements = list(
        axis.text = ggplot2::element_text(size = axis_text_size, colour = "grey30"),
        axis.title.x = ggplot2::element_text(
            size = axis_title_size,
            colour = "black",
            margin = axis_title_x_margin,
            angle = 0
        ),
        axis.title.y = ggplot2::element_text(
            size = axis_title_size,
            colour = "black",
            margin = ggplot2::margin(r = 20),
            angle = 90
        ),
        plot.title = ggplot2::element_text(
            size = title_size,
            hjust = 0.5,
            face = "bold",
            margin = ggplot2::margin(b = 20)
        ),
        legend.text = ggplot2::element_text(size = legend_text_size, colour = "black"),
        legend.title = ggplot2::element_text(
            size = legend_title_size,
            colour = "black",
            face = "bold"
        ),
        strip.text = ggplot2::element_text(
            size = strip_text_size,
            face = "plain",
            color = "black",
            margin = ggplot2::margin(10, 0, 10, 0)
        ),
        strip.background = element_rect (fill = "#e5e5e5", colour = "grey60", linewidth = 0.5),
        panel.background = ggplot2::element_rect(fill = "#f3faff", colour = NA),
        panel.border = ggplot2::element_rect(fill = NA, colour = "grey60", linewidth = 0.5),
        panel.grid.major = element_line(colour = "white", linewidth = 0.3),
        panel.grid.minor = element_line(colour = "white", linewidth = 0.15),
        panel.grid.minor.x = element_blank(),
        panel.spacing = grid::unit(panel_spacing, "lines"),
        plot.margin = ggplot2::margin(t = 30)
    )



    if (!is.null(legend_position)) {
        theme_elements$legend.position = legend_position
    }

    if (!is.null(legend_key_height)) {
        theme_elements$legend.key.height = grid::unit(legend_key_height, "cm")
    }

    if (!is.null(strip_text_x_size)) {
        theme_elements$strip.text.x = ggplot2::element_text(
            size = strip_text_x_size,
            color = "black"
        )
    }

    if (!is.null(strip_text_y_size)) {
        theme_elements$strip.text.y = ggplot2::element_text(
            size = strip_text_y_size,
            angle = 270,
            color = "black",
            margin = ggplot2::margin(0, 14, 0, 14)
        )
    }

    do.call(ggplot2::theme_replace, theme_elements)

    options(
        ggplot2.discrete.colour = function(...) {
            ggplot2::scale_colour_manual(values = Dark2, ...)
        },
        ggplot2.discrete.fill = function(...) {
            ggplot2::scale_fill_manual(values = Dark2, ...)
        }
    )
}
