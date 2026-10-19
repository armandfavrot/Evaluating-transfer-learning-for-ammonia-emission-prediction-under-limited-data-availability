# ---------------------------------------------------------------------
### Set up
packages = c(

      "ggplot2",
      "dplyr",
      "tibble", # rownames_to_column
      "tidyr", # pivot_longer
      "stringr", # str_replace
      "gridExtra" # grid.arrange

)

suppressWarnings( suppressMessages (invisible (lapply (packages, FUN = function(X) {do.call ("library", list(X))}))))

data_file = "../00_data_preparation/data.csv"
figures_directory = "pdf"

dir.create(figures_directory, recursive = TRUE, showWarnings = FALSE)

source("../../00_functions/R_functions.R")



set_plot_theme (
    axis_title_x_margin = margin(t = 10),
    legend_position = NULL,
    legend_text_size = 18,
    legend_title_size = 18,
    legend_key_height = NULL,
    strip_text_y_size = NULL,
    panel_spacing = 2
)

options(
  ggplot2.discrete.colour = function(...) {
    scale_colour_brewer(palette = "Dark2", ...)
  },
  ggplot2.discrete.fill = function(...) {
    scale_fill_brewer(palette = "Dark2", ...)
  }
)



data = read.csv (file = data_file)



# ---------------------------------------------------------------------
### Figure 1 : data description
fig_1 = data %>%
  mutate (meas_tech_origin = recode (meas_tech_origin, "wt" = "Wind tunnel", "CaractAir" = "CaractAir", "cps" = "Cps", "micro met" = "Micromet.", "chamber" = "Dynamic chamber")) %>%
  mutate (meas_tech_origin = factor (meas_tech_origin, levels = c ("Micromet.", "Cps", "Wind tunnel", "Dynamic chamber", "CaractAir"))) %>%
  ggplot () +
    #geom_line (aes (x = ct_origin, y = e_cum_origin / tan_app_origin, group = id), alpha = 0.1) +
    geom_line (aes (x = ct_origin, y = e_cum_origin, group = id), alpha = 0.1) +
    facet_wrap (~ meas_tech_origin, scales = "free_x") +
    theme (axis.title.x = element_text (size = 18)) +
    xlab ("Time since fertilizer application (h)") +
    #ylab ("Cumulative emissions (frac. applied TAN)") +
    ylab (expression("Ammonia emissions (kg N-" * plain(NH)[3] * " ha"^{-1} * ")"))

pdf (file = file.path(figures_directory, "fig_1.pdf"), width = 14, height = 9)
fig_1
dev.off()



# ---------------------------------------------------------------------
### Variability of emissions according to manure source

data_tmp = data %>%
  filter (meas_tech_origin == "micro met") %>%
  filter (fer_origin_origin %in% c ("pig", "cat")) %>%
  filter (ct_origin == max (ct_origin), .by = id) %>%
  mutate (fer_origin_origin = recode (fer_origin_origin, "pig" = "Pig", "cat" = "Cattle"))

data_tmp_quantiles = data_tmp %>%
  summarise (q = list (quantile (e_cum_origin, probs = c (0.1, 0.5, 0.9), na.rm = TRUE)),
             .by = fer_origin_origin) %>%
  unnest_longer (q, values_to = "e_cum_quantile")

data_tmp_mean = data_tmp %>%
  summarise (e_cum_mean = mean (e_cum_origin, na.rm = TRUE), .by = fer_origin_origin)

fig_S4 = data_tmp %>%
  ggplot () +
    geom_histogram (aes (x = e_cum_origin), fill = "#67c5a7", color = "white") +
    geom_vline (data = data_tmp_quantiles,
                aes (xintercept = e_cum_quantile),
                color = "red",
                linetype = "dashed",
                linewidth = 1) +
    geom_vline (data = data_tmp_mean,
                aes (xintercept = e_cum_mean),
                color = "black",
                linetype = "solid",
                linewidth = 1) +
    facet_wrap (~ fer_origin_origin, nrow = 2) +
    xlab (expression("Final cumulative emissions (kg N-" * plain(NH)[3] * " ha"^{-1} * ")")) +
    ylab ("Number of plots")

pdf (file = file.path(figures_directory, "fig_S4.pdf"), width = 10, height = 8)
fig_S4
dev.off()



# ---------------------------------------------------------------------
### Distribution of manure characteristics for cattle vs non-cattle
data_fer_characteristics_base = data %>%
  select (id, meas_tech_origin, fer_origin_origin,
          fer_dm_origin, fer_ph_origin, tan_app_origin,
          app_rate_origin, soil_water_origin, soil_ph_origin,
          soil_dens_origin, soil_oc_origin, crop_z_origin) %>%
  distinct (id, .keep_all = TRUE) %>%
  pivot_longer (cols = c (fer_dm_origin, fer_ph_origin, tan_app_origin,
                          app_rate_origin, soil_water_origin, soil_ph_origin,
                          soil_dens_origin, soil_oc_origin, crop_z_origin),
                names_to = "variable",
                values_to = "value") %>%
  filter (!is.na (value)) %>%
  mutate (variable = recode (variable,
                             "fer_dm_origin" = "Fertilizer dry matter (%)",
                             "fer_ph_origin" = "Fertilizer pH",
                             "tan_app_origin" = "Applied TAN (kg N-NH3/ha)",
                             "app_rate_origin" = "Application rate (t/ha)",
                             "soil_water_origin" = "Soil water (fraction of volume)",
                             "soil_ph_origin" = "Soil pH",
                             "soil_dens_origin" = "Soil bulk density",
                             "soil_oc_origin" = "Soil organic carbon (%)",
                             "crop_z_origin" = "Crop height (cm)")) %>%
  mutate (variable = factor (variable,
                             levels = c ("Fertilizer dry matter (%)", "Fertilizer pH", "Applied TAN (kg N-NH3/ha)",
                                        "Application rate (t/ha)", "Soil water (fraction of volume)", "Soil pH",
                                        "Soil bulk density", "Soil organic carbon (%)", "Crop height (cm)")))

data_fer_characteristics_cattle = data_fer_characteristics_base %>%
  filter (! (fer_origin_origin == "cat" & meas_tech_origin != "micro met")) %>%
  mutate (fer_origin_group = if_else (fer_origin_origin == "cat", "mm cattle", "non-cattle")) %>%
  mutate (fer_origin_group = factor (fer_origin_group, levels = c ("mm cattle", "non-cattle")))

fig_S5 = data_fer_characteristics_cattle %>%
  ggplot (aes (x = fer_origin_group, y = value, fill = fer_origin_group)) +
    geom_boxplot (varwidth = TRUE) +
    facet_wrap (~ variable, scales = "free", nrow = 3) +
    theme (strip.text = element_text (size = 17), axis.text = element_text (size = 20)) +
    xlab (NULL) +
    ylab (NULL) +
    guides (fill = "none")

pdf (file = file.path(figures_directory, "fig_S5.pdf"), width = 14, height = 12)
fig_S5
dev.off()



# ---------------------------------------------------------------------
### Distribution of manure characteristics for pig vs non-pig
data_fer_characteristics_pig = data_fer_characteristics_base %>%
  filter (! (fer_origin_origin == "pig" & meas_tech_origin != "micro met")) %>%
  mutate (fer_origin_group = if_else (fer_origin_origin == "pig", "mm pig", "non-pig")) %>%
  mutate (fer_origin_group = factor (fer_origin_group, levels = c ("mm pig", "non-pig")))

fig_S6 = data_fer_characteristics_pig %>%
  ggplot (aes (x = fer_origin_group, y = value, fill = fer_origin_group)) +
    geom_boxplot (varwidth = TRUE) +
    facet_wrap (~ variable, scales = "free", nrow = 3) +
    theme (strip.text = element_text (size = 17), axis.text = element_text (size = 20)) +
    xlab (NULL) +
    ylab (NULL) +
    guides (fill = "none")

pdf (file = file.path(figures_directory, "fig_S6.pdf"), width = 14, height = 12)
fig_S6
dev.off()



# ---------------------------------------------------------------------
### Final cumulative emissions according to measurement method
data_final_cum_by_meas_tech = data %>%
  filter (ct_origin == max (ct_origin), .by = id) %>%
  mutate (meas_tech_group = if_else (meas_tech_origin == "micro met", "Micrometeorological methods", "Other methods")) %>%
  mutate (meas_tech_group = factor (meas_tech_group, levels = c ("Micrometeorological methods", "Other methods")))

fig_S7 = data_final_cum_by_meas_tech %>%
  ggplot () +
    geom_histogram (aes (x = e_cum_origin), bins = 30, fill = "#67c5a7", color = "white") +
    facet_wrap (~ meas_tech_group, scales = "free_y", nrow = 2) +
    xlab (expression("Final cumulative emissions (kg N-" * plain(NH)[3] * " ha"^{-1} * ")")) +
    ylab ("Number of plots")

pdf (file = file.path(figures_directory, "fig_S7.pdf"), width = 10*1.2, height = 7*1.2)
fig_S7
dev.off()

