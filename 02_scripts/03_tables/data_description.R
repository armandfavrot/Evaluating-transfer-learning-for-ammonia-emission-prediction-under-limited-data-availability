# ---------------------------------------------------------------------
### Set up

packages = c(
    "dplyr"
)

suppressWarnings(suppressMessages(invisible(lapply(
    packages,
    FUN = function(X) {do.call("library", list(X))}
))))

data_file = "../00_data_preparation/data.csv"
tables_directory = "csv"

dir.create(tables_directory, recursive = TRUE, showWarnings = FALSE)

data = read.csv(file = data_file)



# ---------------------------------------------------------------------
### Number of experiments & number of repetitions

data %>% filter (meas_tech_origin == "CaractAir") %>% pull (eid) %>% unique %>% length
data %>% filter (meas_tech_origin != "CaractAir") %>% pull (eid) %>% unique %>% length

data %>%
  filter (meas_tech_origin == "CaractAir") %>%
  select (eid, tr) %>%
  distinct %>%
  count (eid)

data %>%
  filter (meas_tech_origin == "CaractAir") %>%
  select (eid_tr, id) %>%
  distinct %>%
  count (eid_tr)



# ---------------------------------------------------------------------
### Table 2 - Number of experiments for cattle & pig, according to the different measurement methods

n_eid_tr = data$eid_tr %>% unique %>% length

data %>%
  filter (fer_origin_origin %in% c ("pig", "cat")) %>%
  select (eid_tr, fer_origin_origin, meas_tech_origin) %>%
  distinct %>%
  summarise (n_A_bar = n_eid_tr - n (),
             N_MM_A = sum (meas_tech_origin == "micro met"),
             N_wt_A = sum (meas_tech_origin == "wt"),
             n_cps_A = sum (meas_tech_origin == "cps"),
             n_CaractAir_A = sum (meas_tech_origin == "CaractAir"),
             n_Chamber_A = sum (meas_tech_origin == "chamber"),
             .by = fer_origin_origin) %>%
  arrange (fer_origin_origin)



# ---------------------------------------------------------------------
### Table A1 - Number of experiments according to the fertilizer origin & the measurement method

table_A1 = data %>%
  select (eid_tr, id, meas_tech_origin, fer_origin_origin) %>%
  distinct %>%
  summarise (
             n_trials = length (unique (eid_tr)),
             n_plots = length (unique (id)),
             .by = c (meas_tech_origin, fer_origin_origin)) %>%
  arrange (desc (n_trials)) %>%
  arrange (match (meas_tech_origin, c ("micro met", "CaractAir", "wt", "chamber", "cps")))

write.csv (table_A1, file = file.path(tables_directory, "table_A1.csv"), row.names = FALSE)



# ---------------------------------------------------------------------
### Table A2 - Number of experiments according to the measurement method

table_A2 = data %>%
  select (eid_tr, meas_tech_origin) %>%
  distinct %>%
  count (meas_tech_origin) %>%
  arrange (desc (n))

write.csv (table_A2, file = file.path(tables_directory, "table_A2.csv"), row.names = FALSE)
