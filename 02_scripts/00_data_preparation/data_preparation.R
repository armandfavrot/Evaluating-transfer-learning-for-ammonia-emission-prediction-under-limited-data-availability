# ---------------------------------------------------------------------
### Set up

packages = c(
    "dplyr",
    "tidyr"
)

suppressWarnings(suppressMessages(invisible(lapply(
    packages,
    FUN = function(X) {do.call("library", list(X))}
))))

input_directory = "../../01_data"
output_file = "data.csv"



# ---------------------------------------------------------------------
### Data import

data_alfam2 = read.csv(
    file = file.path(input_directory, "data_alfam2.csv"),
    row.names = 1
)

data_caractair = read.csv(
    file = file.path(input_directory, "data_caractair.csv"),
    row.names = 1
)

# These variables were stored as Date in data_caractair_clean.Rdata.
data_caractair$app_start = as.Date(data_caractair$app_start)
data_caractair$meas_start = as.Date(data_caractair$meas_start)

data = rbind(data_alfam2, data_caractair)



# ---------------------------------------------------------------------
### Temporal resolution

data1 = data %>%
    mutate(big_trial = ifelse(n() > 200, "yes", "no"), .by = id) %>%
    filter(
        big_trial == "no" |
            interval %in% ((floor(4 / mean(dt)) + 1) * c(1 : 1000)),
        .by = id
    ) %>%

    # Recalculate the flux and absolute emissions
    mutate(e_cum_shift = lag(e_cum, default = 0), .by = id) %>%
    mutate(delta_e_cum = (e_cum - e_cum_shift)) %>%
    mutate(j_nh3 = delta_e_cum / dt)



# ---------------------------------------------------------------------
### Variables not applicable

data2 = data1 %>%

    mutate(crop = ifelse(crop == "cereal" & crop_z == "0", "bare soil", crop)) %>%
    mutate(crop = ifelse(crop == "other" & crop_z == "0", "bare soil", crop)) %>%

    mutate(crop_z = ifelse(crop_z == "0", "nc", crop_z)) %>%
    mutate(crop_z = ifelse(crop == "bare soil", "nc", crop_z)) %>%

    mutate(time_incorp = ifelse(incorp == "none", "nc", time_incorp)) %>%

    mutate(furrow_z = ifelse(
        app_method %in% c("bc", "bsth") & incorp == "none",
        "nc",
        furrow_z
    )) %>%

    mutate(furrow_z = ifelse(furrow_z == "0-20", "20", furrow_z)) %>%
    mutate(furrow_z = ifelse(furrow_z == "0-18", "18", furrow_z)) %>%
    mutate(furrow_z = na_if(furrow_z, ""))



# ---------------------------------------------------------------------
### Missing categorical values

data3 = data2 %>%

    mutate(crop = replace_na(crop, "unknown")) %>%

    mutate(fer_forme = replace_na(fer_forme, "unknown")) %>%
    mutate(fer_trt3 = replace_na(fer_trt3, "unknown")) %>%
    mutate(soil_type = replace_na(soil_type, "unknown")) %>%

    mutate(crop_res = ifelse(crop_res == "", "No", crop_res)) %>%
    mutate(crop_res = recode(crop_res, "no" = "No", "none" = "No")) %>%
    mutate(crop_res = replace_na(crop_res, "unknown")) %>%

    mutate(till = recode(till, "none" = "no")) %>%
    mutate(till = replace_na(till, "unknown"))



# ---------------------------------------------------------------------
### Interpolation and rain

data4 = data3 %>%
    mutate(prop_na_temp = sum(is.na(air_temp)) / n(), .by = id) %>%
    mutate(
        air_temp = ifelse(
            id %in% id[(prop_na_temp > 0) & (prop_na_temp < 1)],
            approx(x = ct, y = air_temp, xout = ct, rule = 2)[[2]],
            air_temp
        ),
        .by = id
    )

data5 = data4 %>%
    mutate(prop_na_wind = sum(is.na(wind_2m)) / n(), .by = id) %>%
    mutate(
        wind_2m = ifelse(
            id %in% id[(prop_na_wind > 0) & (prop_na_wind < 1)],
            approx(x = ct, y = wind_2m, xout = ct, rule = 2)[[2]],
            wind_2m
        ),
        .by = id
    )

data6 = data5 %>%
    mutate(rain_rate = replace_na(rain_rate, 0)) %>%
    mutate(rain_cum = cumsum(rain_rate * dt), .by = id)



# ---------------------------------------------------------------------
### Missing-value indicators

# numerical variables with NAs but no NC
vars1 = c(
    "air_temp", "wind_2m", "fer_ph", "fer_dm", "soil_water", "soil_ph",
    "soil_dens", "soil_oc", "soil_sand", "soil_silt", "soil_clay"
)

# numerical variables with both NAs and NCs
vars2 = c("time_incorp", "furrow_z", "crop_z")

data7 = data6 %>%

    mutate(across(
        all_of(vars1),
        ~ ifelse(is.na(.x), "unknown", "known"),
        .names = "{.col}_ind"
    )) %>%

    mutate(across(
        all_of(vars2),
        ~ case_when(
            is.na(.x) ~ "unknown",
            .x == "nc" ~ "not_applicable",
            TRUE ~ "known"
        ),
        .names = "{.col}_ind"
    )) %>%

    mutate(across(all_of(vars2), ~ na_if(.x, "nc"))) %>%
    mutate(across(all_of(vars2), as.numeric))



# ---------------------------------------------------------------------
### Time-level variable scaling

x = c(
    "dt", "ct", "e_cum", "delta_e_cum", "j_nh3",
    "air_temp", "wind_2m", "rain_rate", "rain_cum"
)

data8 = data7 %>%

    mutate(across(all_of(x), identity, .names = "{.col}_origin")) %>%

    mutate_at(x, function(y) y / max(abs(y), na.rm = TRUE)) %>%

    mutate(air_temp = ifelse(air_temp_ind == "unknown", 2, air_temp)) %>%
    mutate(wind_2m = ifelse(wind_2m_ind == "unknown", 2, wind_2m))



# ---------------------------------------------------------------------
### Plot-level variable scaling

x = c(
    "fer_ph", "fer_dm", "tan_app", "app_rate", "soil_water", "soil_ph",
    "soil_dens", "soil_oc", "soil_sand", "soil_silt", "soil_clay",
    "furrow_z", "time_incorp", "crop_z"
)

x_ind = x[which(paste(x, "_ind", sep = "") %in% colnames(data8))]

df_scale_plot_level_variables = data8 %>%
    select(any_of(c("id", x))) %>%
    distinct %>%
    mutate_at(x, function(y) y / max(abs(y), na.rm = TRUE))

data9 = data8 %>%

    mutate(across(all_of(x), identity, .names = "{.col}_origin")) %>%

    select(-any_of(x)) %>%

    left_join(df_scale_plot_level_variables, by = "id") %>%

    mutate(
        across(
            all_of(x_ind),
            ~ {
                ind_col = paste0(cur_column(), "_ind")

                case_when(
                    get(ind_col) == "unknown" ~ 2,
                    get(ind_col) == "not_applicable" ~ -2,
                    TRUE ~ .
                )
            }
        )
    )



# ---------------------------------------------------------------------
### Variable selection

data10 = data9 %>%

    select(
        datatype,
        country, institute, eid, tr, id, rep,
        app_start, meas_start, year,
        interval, dt, ct,
        e_cum, delta_e_cum, j_nh3,
        air_temp, wind_2m, rain_rate, rain_cum,
        meas_tech,
        app_method, incorp, time_incorp, furrow_z,
        fer_origin, fer_forme, fer_trt1, fer_trt2, fer_trt3, fer_ph, fer_dm,
        tan_app, app_rate,
        soil_type, soil_water, soil_ph, soil_dens, soil_oc, soil_clay, soil_sand, soil_silt,
        crop, crop_z,
        till,

        air_temp_ind, wind_2m_ind,
        fer_ph_ind, fer_dm_ind,
        soil_water_ind, soil_ph_ind, soil_dens_ind, soil_oc_ind,
        soil_clay_ind, soil_sand_ind, soil_silt_ind,
        crop_z_ind,
        time_incorp_ind, furrow_z_ind,

        dt_origin, ct_origin,
        e_cum_origin, delta_e_cum_origin, j_nh3_origin,
        air_temp_origin, wind_2m_origin, rain_rate_origin, rain_cum_origin,
        time_incorp_origin, furrow_z_origin,
        fer_ph_origin, fer_dm_origin,
        tan_app_origin, app_rate_origin,
        soil_water_origin, soil_ph_origin, soil_dens_origin, soil_oc_origin,
        soil_clay_origin, soil_sand_origin, soil_silt_origin,
        crop_z_origin
    ) %>%

    mutate(eid_tr = paste(eid, tr), .after = tr) %>%

    # Trials with a single observation cannot be used by the RNN
    filter(!(id %in% id[n() == 1]), .by = id) %>%

    # unexplained variability (different treatment but no differences in the covariates)
    filter(!(eid %in% c(7, 8)))



# ---------------------------------------------------------------------
### Numerical indicators

data11 = data10 %>%

    mutate(across(
        .cols = c(
            "fer_ph_ind", "fer_dm_ind",
            "soil_water_ind", "soil_ph_ind", "soil_dens_ind", "soil_oc_ind",
            "soil_clay_ind", "soil_sand_ind", "soil_silt_ind",
            "crop_z_ind",
            "air_temp_ind", "wind_2m_ind",
            "time_incorp_ind", "furrow_z_ind"
        ),

        .fns = ~ recode(
            .x,
            "unknown" = 2,
            "known" = 0,
            "not_applicable" = -2
        )
    ))



# ---------------------------------------------------------------------
### Categorical variables

data12 = data11 %>%

    mutate(across(
        .cols = c(
            "app_method", "incorp",
            "meas_tech",
            "fer_origin", "fer_forme",
            "fer_trt1", "fer_trt2", "fer_trt3",
            "crop", "soil_type", "till",
            "institute"
        ),

        identity, .names = "{.col}_origin"
    )) %>%

    mutate(across(
        .cols = c(
            "app_method", "incorp",
            "meas_tech",
            "fer_origin", "fer_forme",
            "fer_trt1", "fer_trt2", "fer_trt3",
            "crop", "soil_type", "till",
            "institute"
        ),

        .fns = function(z) as.numeric(factor(z))
    ))



# ---------------------------------------------------------------------
### Unscaled variables with indicator codes

data13 = data12 %>%

    mutate(across(
        .cols = c(
            "ct_origin", "dt_origin", "rain_rate_origin",
            "tan_app_origin", "app_rate_origin"
        ),
        identity,
        .names = "{.col}_2"
    )) %>%

    mutate(
        across(
            all_of(paste0(
                c(
                    "time_incorp", "furrow_z", "fer_dm", "fer_ph",
                    "soil_water", "soil_ph", "soil_oc", "soil_dens",
                    "crop_z", "air_temp", "wind_2m"
                ),
                "_origin"
            )),
            ~ {
                var = sub("_origin$", "", cur_column())
                ind_col = paste0(var, "_ind")

                case_when(
                    get(ind_col) == 2 ~ 1000,
                    get(ind_col) == -2 ~ -1000,
                    TRUE ~ .
                )
            },
            .names = "{.col}_2"
        )
    )



# ---------------------------------------------------------------------
### Final character cleanup and export

data14 = data13 %>%

    # Python reads the string "None" as a missing value
    mutate(across(
        .cols = where(is.character),
        .fns = ~ recode(
            .x,
            "None" = "none",
            .default = .x
        )
    ))

write.csv(data14, file = output_file, row.names = FALSE)
