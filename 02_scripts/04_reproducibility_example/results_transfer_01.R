# ---------------------------------------------------------------------
### Reproducibility figures for experiment transfer_01

packages <- c("ggplot2", "dplyr")
suppressPackageStartupMessages(
  invisible(lapply(packages, library, character.only = TRUE))
)

results_file <- "results/df_res_1.csv"
images_dir <- "images"
dir.create(images_dir, recursive = TRUE, showWarnings = FALSE)

df_res1 <- read.csv(results_file)



# ---------------------------------------------------------------------
### Theme and colours

theme_set(theme_gray())
theme_update(
  axis.text = element_text(size = 18),
  axis.title.x = element_text(size = 18, margin = margin(t = 10)),
  axis.title.y = element_text(size = 18, margin = margin(r = 20)),
  legend.text = element_text(size = 17),
  legend.title = element_text(size = 19, face = "bold"),
  strip.text = element_text(
    size = 20, face = "bold", color = "white",
    margin = margin(10, 0, 10, 0)
  ),
  strip.background = element_rect(fill = "#000080"),
  panel.background = element_rect(fill = "#f3faff"),
  panel.grid.major = element_line(colour = "grey"),
  panel.grid.minor = element_line(colour = "grey"),
  panel.spacing = grid::unit(1.4, "lines"),
  plot.margin = margin(t = 30)
)

model_colours <- c(
  "source_to_target_mm" = "#D95F02",
  "source_to_alternative_to_target_mm" = "#F28E2B",
  "alternative_to_target_mm" = "#FBBF77",
  "target_mm_only" = "#A6CEE3",
  "target_mean" = "#1F78B4"
)



# ---------------------------------------------------------------------
### Prepare results

df_res1_ref <- df_res1 %>%
  filter(strategy == "target_mm_only", p == "all")

mae_ref <- df_res1_ref %>%
  summarise(MAE = mean(mae), .by = target_mm_data)

plot_data <- df_res1 %>%
  filter(!(strategy == "target_mm_only" & p == "all"))

with_alternative <- plot_data %>%
  filter(strategy %in% c(
    "source_to_alternative_to_target_mm",
    "alternative_to_target_mm"
  )) %>%
  mutate(
    origin = recode(
      target_mm_data,
      "micro_met_cat" = "cat",
      "micro_met_pig" = "pig"
    ),
    alternative_method = recode(
      alternative_data,
      "wt_cat" = "wt",
      "wt_pig" = "wt"
    )
  )

without_alternative <- plot_data %>%
  filter(strategy %in% c(
    "source_to_target_mm",
    "target_mm_only",
    "target_mean"
  )) %>%
  mutate(
    origin = recode(
      target_mm_data,
      "micro_met_cat" = "cat",
      "micro_met_pig" = "pig"
    ),
    alternative_method = "wt"
  )

df <- bind_rows(with_alternative, without_alternative)

df_hline <- mae_ref %>%
  filter(target_mm_data == "micro_met_cat") %>%
  summarise(yintercept = mean(MAE)) %>%
  mutate(origin = "A = Cattle")

if (nrow(df_hline) == 0 || is.na(df_hline$yintercept)) {
  stop("Unable to calculate the cattle reference MAE from p = all.")
}

model_levels <- c(
  "source_to_target_mm",
  "source_to_alternative_to_target_mm",
  "alternative_to_target_mm",
  "target_mm_only",
  "target_mean"
)

df_plot <- df %>%
  mutate(
    Model = factor(strategy, levels = model_levels),
    origin = recode(origin, "cat" = "A = Cattle", "pig" = "A = Pig"),
    origin = factor(origin, levels = c("A = Cattle", "A = Pig")),
    alternative_method = recode(alternative_method, "wt" = "x = Wind tunnel")
  )

common_layers <- list(
  geom_boxplot(aes(x = p, y = mae, fill = Model), outlier.alpha = 0.45),
  geom_hline(
    data = df_hline,
    aes(yintercept = yintercept),
    linewidth = 0.8,
    linetype = 2
  ),
  theme(
    legend.position = "bottom",
    legend.key.height = grid::unit(0.6, "cm"),
    axis.title.x = element_text(margin = margin(0, 0, 10, 0)),
    strip.text.x = element_text(color = "white"),
    strip.text.y = element_text(
      size = 20, angle = 270, color = "white",
      margin = margin(0, 14, 0, 14)
    )
  ),
  xlab("p"),
  ylab(expression("MAE (kg N-" * plain(NH)[3] * " ha"^{-1} * ")"))
)

save_pdf <- function(plot, filename, width, height) {
  ggsave(
    filename = file.path(images_dir, filename),
    plot = plot,
    device = "pdf",
    width = width,
    height = height,
    units = "in"
  )
}



# ---------------------------------------------------------------------
### Figure 1.1: models without the alternative-measurement transfer

breaks_1_1 <- c(
  "source_to_target_mm", "target_mm_only", "target_mean"
)

labels_1_1 <- expression(
  paste("1-", bar(E(A)), "-2-", plain(mm)[italic(p)], "(A)"),
  paste("1-", plain(mm)[italic(p)], "(A)"),
  paste("mean-model-", plain(mm)[italic(p)], "(A)")
)

fig_1 <- df_plot %>%
  filter(alternative_method == "x = Wind tunnel", Model %in% breaks_1_1) %>%
  ggplot() +
  common_layers +
  facet_grid(~ origin, scales = "free_y") +
  scale_fill_manual(
    values = model_colours,
    breaks = breaks_1_1,
    labels = labels_1_1,
    drop = FALSE
  )

save_pdf(fig_1, "fig_1.pdf", width = 14, height = 6)



# ---------------------------------------------------------------------
### Figure 1.2: source-domain transfer with and without wind tunnel

breaks_1_2 <- c(
  "source_to_target_mm",
  "source_to_alternative_to_target_mm",
  "target_mm_only", "target_mean"
)

labels_1_2 <- expression(
  paste("1-", bar(E(A)), "-2-", plain(mm)[italic(p)], "(A)"),
  paste("1-", bar(E(A)), "-2-x(A)-3-", plain(mm)[italic(p)], "(A)"),
  paste("1-", plain(mm)[italic(p)], "(A)"),
  paste("mean-model-", plain(mm)[italic(p)], "(A)")
)

fig_2 <- df_plot %>%
  filter(Model %in% breaks_1_2) %>%
  ggplot() +
  common_layers +
  facet_grid(alternative_method ~ origin, scales = "free_y") +
  scale_fill_manual(
    values = model_colours,
    breaks = breaks_1_2,
    labels = labels_1_2,
    drop = FALSE
  )

save_pdf(fig_2, "fig_2.pdf", width = 14, height = 10)



# ---------------------------------------------------------------------
### Figure 1.3: wind-tunnel transfer without the source-only model

breaks_1_3 <- c(
  "source_to_alternative_to_target_mm",
  "alternative_to_target_mm",
  "target_mm_only", "target_mean"
)

labels_1_3 <- expression(
  paste("1-", bar(E(A)), "-2-x(A)-3-", plain(mm)[italic(p)], "(A)"),
  paste("1-x(A)-2-", plain(mm)[italic(p)], "(A)"),
  paste("1-", plain(mm)[italic(p)], "(A)"),
  paste("mean-model-", plain(mm)[italic(p)], "(A)")
)

fig_3 <- df_plot %>%
  filter(Model %in% breaks_1_3) %>%
  ggplot() +
  common_layers +
  facet_grid(alternative_method ~ origin, scales = "free_y") +
  scale_fill_manual(
    values = model_colours,
    breaks = breaks_1_3,
    labels = labels_1_3,
    drop = FALSE
  )

save_pdf(fig_3, "fig_3.pdf", width = 14, height = 10)
