# ---------------------------------------------------------------------
### Set up
packages = c(
    "ggplot2",
    "dplyr"
)

suppressWarnings( suppressMessages (invisible (lapply (packages, FUN = function(X) {do.call ("library", list(X))}))))

results_directory = "../01_transfer_learning/results"
figures_directory = "pdf"

dir.create(figures_directory, recursive = TRUE, showWarnings = FALSE)

source("../../00_functions/R_functions.R")



set_plot_theme(strip_text_y_size = 18)


# ---------------------------------------------------------------------
### Boxplots transfer learning for CaractAir & wt
df_res2_folds = read.csv (file = file.path(results_directory, "df_res_2.csv"))

df_res2 = df_res2_folds %>%
    summarise (
        mae = mean (mae),
        .by = c (
            strategy, source_domain, alternative_data,
            target_mm_data, p, repetition
        )
    )

df_res2_ref = df_res2 %>%
    filter (strategy == "target_mm_only" & p == "all")

MAE_ref = df_res2_ref %>%
    summarise (MAE = mean (mae), .by = target_mm_data)

plot_data = df_res2 %>%
    filter (! (strategy == "target_mm_only" & p == "all"))


df1 = plot_data %>%
    filter (strategy %in% c (
        "source_to_alternative_to_target_mm",
        "alternative_to_target_mm"
    )) %>%
    mutate (origin = recode (
        target_mm_data,
        "micro_met_cat" = "cat",
        "micro_met_pig" = "pig"
    )) %>%
    mutate (alternative_method = recode (
        alternative_data,
        "CaractAir_cat" = "CaractAir", "CaractAir_pig" = "CaractAir",
        "chamber_cat" = "chamber", "chamber_pig" = "chamber",
        "cps_cat" = "cps", "cps_pig" = "cps",
        "wt_pig" = "wt", "wt_cat" = "wt"
    ))


df2 = plot_data %>%
    filter (strategy %in% c (
        "source_to_target_mm",
        "target_mm_only",
        "target_mean"
    )) %>%
    mutate (origin = recode (
        target_mm_data,
        "micro_met_cat" = "cat",
        "micro_met_pig" = "pig"
    )) %>%
    cross_join (data.frame (
        alternative_method = c ("CaractAir", "chamber", "cps", "wt")
    ))


df = rbind (df1, df2)

MAE_cat = MAE_ref %>%
    filter (target_mm_data == "micro_met_cat") %>%
    pull (MAE)
MAE_pig = MAE_ref %>%
    filter (target_mm_data == "micro_met_pig") %>%
    pull (MAE)


df_hline = data.frame (
    origin = c ("cat", "pig"),
    yintercept = c (MAE_cat, MAE_pig)
) %>%
    mutate (origin = recode (
        origin,
        "cat" = "A = Cattle",
        "pig" = "A = Pig"
    )) %>%
    mutate (origin = factor (
        origin,
        levels = c ("A = Cattle", "A = Pig")
    ))


df_plot = df %>%
    mutate (Model = factor (strategy, levels = c (
        "source_to_target_mm",
        "source_to_alternative_to_target_mm",
        "alternative_to_target_mm",
        "target_mm_only",
        "target_mean"
    ))) %>%
    mutate (origin = recode (
        origin,
        "cat" = "A = Cattle",
        "pig" = "A = Pig"
    )) %>%
    mutate (origin = factor (
        origin,
        levels = c ("A = Cattle", "A = Pig")
    )) %>%
    mutate (alternative_method = recode (
        alternative_method,
        "CaractAir" = "x = CaractAir",
        "wt" = "x = Wind tunnel",
        "chamber" = "x = Dyn. chamber",
        "cps" = "x = Cps"
    )) %>%
    mutate (alternative_method = factor (
        alternative_method,
        levels = c ("x = Cps", "x = Wind tunnel", "x = Dyn. chamber", "x = CaractAir")
    ))

df_plot_folds = df_plot %>%
    select (-mae) %>%
    left_join (
        df_res2_folds,
        by = c (
            "strategy", "source_domain", "alternative_data",
            "target_mm_data", "p", "repetition"
        ),
        relationship = "many-to-many"
    )


df_arrows_fig_S2 = df_plot %>%
    summarise (
        hidden_mae = max (mae),
        upper_fence = quantile (mae, 0.75) + 1.5 * IQR (mae),
        box_upper = max (mae[mae <= upper_fence]),
        outlier_label = paste (
            round (sort (mae[mae > upper_fence], decreasing = TRUE), 1),
            collapse = "\n"
        ),
        .by = c (origin, alternative_method, Model, p)
    ) %>%
    filter (hidden_mae > 38) %>%
    mutate (
        label = paste0 (outlier_label, "\n\u2191"),
        label_y = box_upper * 1.18
    )

df_hidden_outlier_fig_S2 = df_plot %>%
    mutate (
        upper_fence = quantile (mae, 0.75) + 1.5 * IQR (mae),
        group_max = max (mae),
        .by = c (origin, alternative_method, Model, p)
    ) %>%
    filter (group_max > 38, mae > upper_fence, mae <= 38)


fig_S2 = df_plot %>%
    ggplot () +
        geom_boxplot (aes (x = p, y = mae, fill = Model), outlier.alpha = 0.45) +
        geom_hline(
            data = df_hline,
            aes(yintercept = yintercept),
            linewidth = 0.8,
            linetype = 2
        ) +
        geom_point (
            data = df_hidden_outlier_fig_S2 %>%
                filter (Model == "alternative_to_target_mm"),
            aes (x = p, y = mae),
            position = position_nudge (x = 0.25),
            colour = "#f3faff",
            size = 2.5,
            inherit.aes = FALSE
        ) +
        geom_text (
            data = df_arrows_fig_S2 %>%
                filter (Model == "source_to_alternative_to_target_mm"),
            aes (x = p, y = label_y * 1.08, label = label),
            inherit.aes = FALSE,
            size = 3.5 
        ) +
        geom_text (
            data = df_arrows_fig_S2 %>%
                filter (Model == "alternative_to_target_mm"),
            aes (x = p, y = label_y * 1.05, label = label),
            position = position_nudge (x = 0.25),
            inherit.aes = FALSE,
            size = 3.5
        ) +
        facet_grid (alternative_method ~ origin, scales = "free_y") +
        scale_y_log10 () +
        coord_cartesian (ylim = c (NA, 38)) +
        scale_fill_manual (values = c ("source_to_target_mm" = Dark2[2],
                                       "source_to_alternative_to_target_mm" = "#F28E2B",
                                       "alternative_to_target_mm" = "#FBBF77",
                                       "target_mm_only" = "#A6CEE3",
                                       "target_mean" = "#1F78B4"),
                           breaks = c ("source_to_target_mm", "source_to_alternative_to_target_mm", "alternative_to_target_mm", "target_mm_only", "target_mean"),
                           labels = expression (paste ("1-", bar (E(A)), "-2-", plain(mm)[italic(p)], "(A)"),
                                                paste ("1-", bar (E(A)), "-2-x(A)-3-", plain(mm)[italic(p)], "(A)"),
                                                paste ("1-x(A)-2-", plain(mm)[italic(p)], "(A)"),
                                                paste ("1-", plain(mm)[italic(p)], "(A)"),
                                                paste ("mean-model-", plain(mm)[italic(p)], "(A)"))) +
        guides (fill = guide_legend(nrow = 2, byrow = TRUE)) +
        xlab ("p") +
        ylab (expression("MAE (kg N-" * plain(NH)[3] * " ha"^{-1} * ")"))


cairo_pdf (file = file.path(figures_directory, "fig_S2.pdf"), width = 14, height = 14)
fig_S2
dev.off()



# ---------------------------------------------------------------------
### Figure S9

fig_S9 = df_plot_folds %>%
    ggplot () +
        geom_boxplot (aes (x = p, y = mae, fill = Model), outlier.alpha = 0.45) +
        geom_hline(
            data = df_hline,
            aes(yintercept = yintercept),
            linewidth = 0.8,
            linetype = 2
        ) +
        facet_grid (alternative_method ~ origin, scales = "free_y") +
        scale_fill_manual (values = c ("source_to_target_mm" = Dark2[2],
                                       "source_to_alternative_to_target_mm" = "#F28E2B",
                                       "alternative_to_target_mm" = "#FBBF77",
                                       "target_mm_only" = "#A6CEE3",
                                       "target_mean" = "#1F78B4"),
                           breaks = c ("source_to_target_mm", "source_to_alternative_to_target_mm", "alternative_to_target_mm", "target_mm_only", "target_mean"),
                           labels = expression (paste ("1-", bar (E(A)), "-2-", plain(mm)[italic(p)], "(A)"),
                                                paste ("1-", bar (E(A)), "-2-x(A)-3-", plain(mm)[italic(p)], "(A)"),
                                                paste ("1-x(A)-2-", plain(mm)[italic(p)], "(A)"),
                                                paste ("1-", plain(mm)[italic(p)], "(A)"),
                                                paste ("mean-model-", plain(mm)[italic(p)], "(A)"))) +
        guides (fill = guide_legend(nrow = 2, byrow = TRUE)) +
        scale_y_log10 () +
        xlab ("p") +
        ylab (expression("MAE (kg N-" * plain(NH)[3] * " ha"^{-1} * ")"))

pdf (file = file.path(figures_directory, "fig_S9.pdf"), width = 14, height = 14)
fig_S9
dev.off()
