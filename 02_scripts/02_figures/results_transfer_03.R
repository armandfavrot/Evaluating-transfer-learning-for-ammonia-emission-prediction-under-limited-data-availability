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


set_plot_theme(strip_text_x_size = 20, strip_text_y_size = 18)


# ---------------------------------------------------------------------
### Boxplots transfer learning for CaractAir & wt
df_res3_folds = read.csv (file = file.path(results_directory, "df_res_3.csv"))

df_res3 = df_res3_folds %>%
    summarise (
        mae = mean (mae),
        .by = c (
            strategy, source_domain, alternative_data,
            target_mm_data, p, repetition
        )
    )

df_res3_ref = df_res3 %>%
    filter (strategy == "target_mm_only" & p == "all")

MAE_ref = df_res3_ref %>%
    summarise (MAE = mean (mae), .by = target_mm_data)

plot_data = df_res3 %>%
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
        df_res3_folds,
        by = c (
            "strategy", "source_domain", "alternative_data",
            "target_mm_data", "p", "repetition"
        ),
        relationship = "many-to-many"
    )


fig_S3 = df_plot %>%
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
        xlab ("p") +
        ylab (expression("MAE (kg N-" * plain(NH)[3] * " ha"^{-1} * ")"))


pdf (file = file.path(figures_directory, "fig_S3.pdf"), width = 14, height = 13)
fig_S3
dev.off()



# ---------------------------------------------------------------------
### Figure S10

fig_S10 = df_plot_folds %>%
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

pdf (file = file.path(figures_directory, "fig_S10.pdf"), width = 14, height = 14)
fig_S10
dev.off()
