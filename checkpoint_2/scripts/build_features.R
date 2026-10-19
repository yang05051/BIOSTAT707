# Cleaning and wide-table construction carried over verbatim from Checkpoint 1.
suppressPackageStartupMessages({library(data.table); library(dplyr); library(tidyr); library(readr)})
data_dir <- "data"
set_a_dir <- file.path(data_dir, "set-a")
out_dir <- "output"
dir.create(out_dir, recursive=TRUE, showWarnings=FALSE)
expected_n <- 4000L
#| label: check-data
record_files <- sort(list.files(set_a_dir, pattern = "^[0-9]+\\.txt$", full.names = TRUE))
outcome_path <- file.path(data_dir, "Outcomes-a.txt")

stopifnot(
  "data/set-a/ is missing" = dir.exists(set_a_dir),
  "data/Outcomes-a.txt is missing" = file.exists(outcome_path),
  "Expected exactly 4,000 set-A record files" = length(record_files) == expected_n
)

outcomes <- fread(outcome_path, na.strings = "-1") |>
  as_tibble() |>
  rename(
    record_id = RecordID,
    saps_i = `SAPS-I`,
    sofa = SOFA,
    length_of_stay = Length_of_stay,
    survival_days = Survival,
    in_hospital_death = `In-hospital_death`
  )

file_ids <- as.integer(sub("\\.txt$", "", basename(record_files)))
stopifnot(
  "Expected exactly 4,000 outcome rows" = nrow(outcomes) == expected_n,
  "Record files and outcome IDs do not match" = setequal(file_ids, outcomes$record_id),
  "Outcome must be coded 0/1" = all(outcomes$in_hospital_death %in% c(0, 1))
)

#| label: load-and-clean
read_record <- function(path) {
  x <- fread(path, colClasses = c(Time = "character", Parameter = "character", Value = "numeric"))
  stopifnot(identical(names(x), c("Time", "Parameter", "Value")))
  pieces <- tstrsplit(x$Time, ":", fixed = TRUE)
  data.table(
    record_id = as.integer(sub("\\.txt$", "", basename(path))),
    source_row = seq_len(nrow(x)),
    time = x$Time,
    time_hours = as.numeric(pieces[[1]]) + as.numeric(pieces[[2]]) / 60,
    parameter = x$Parameter,
    raw_value = x$Value
  )
}

long <- rbindlist(lapply(record_files, read_record), use.names = TRUE) |>
  as_tibble()

descriptor_vars <- c("RecordID", "Age", "Gender", "Height", "ICUType", "Weight")

plausibility <- tribble(
  ~parameter,     ~lower, ~upper,
  "Age",              15,    120,
  "Gender",            0,      1,
  "Height",          100,    250,
  "ICUType",           1,      4,
  "Weight",           20,    500,
  "Albumin",         0.5,      8,
  "ALP",               5,   3000,
  "ALT",               1,  10000,
  "AST",               1,  20000,
  "Bilirubin",       0.1,    100,
  "BUN",               1,    300,
  "Cholesterol",      20,   1000,
  "Creatinine",      0.1,     30,
  "DiasABP",          10,    180,
  "FiO2",           0.20,      1,
  "GCS",               3,     15,
  "Glucose",          10,   1500,
  "HCO3",              2,     60,
  "HCT",               5,     75,
  "HR",               10,    300,
  "K",                 1,     12,
  "Lactate",         0.1,     30,
  "Mg",              0.2,     10,
  "MAP",              10,    250,
  "MechVent",          0,      1,
  "Na",               80,    200,
  "NIDiasABP",        10,    180,
  "NIMAP",            10,    250,
  "NISysABP",         20,    300,
  "PaCO2",             5,    250,
  "PaO2",             10,    700,
  "pH",              6.5,      8,
  "Platelets",         1,   2000,
  "RespRate",          1,    100,
  "SaO2",             20,    100,
  "SysABP",           20,    300,
  "Temp",             25,     45,
  "TropI",             0,    100,
  "TropT",             0,     50,
  "Urine",             0,   5000,
  "WBC",             0.1,    200
)

long <- long |>
  left_join(plausibility, by = "parameter") |>
  mutate(
    is_descriptor = source_row <= 6 & parameter %in% descriptor_vars,
    quality_flag = case_when(
      raw_value == -1 ~ "missing_sentinel",
      !is.na(lower) & (raw_value < lower | raw_value > upper) ~ "outside_plausibility_bound",
      TRUE ~ "as_recorded"
    ),
    value = if_else(quality_flag == "as_recorded", raw_value, NA_real_)
  ) |>
  select(record_id, source_row, time, time_hours, parameter,
         raw_value, value, quality_flag, is_descriptor)

stopifnot(
  "Unexpected elapsed time" = all(long$time_hours >= 0 & long$time_hours <= 48),
  "Some files contain a mismatched RecordID row" = long |>
    filter(parameter == "RecordID") |>
    summarise(ok = all(record_id == raw_value)) |>
    pull(ok)
)

write_csv(long, file.path(out_dir, "set-a_long.csv"), na = "")

#| label: build-wide
static <- long |>
  filter(is_descriptor, parameter != "RecordID") |>
  group_by(record_id, parameter) |>
  summarise(value = dplyr::first(value), .groups = "drop") |>
  pivot_wider(names_from = parameter, values_from = value) |>
  rename(age = Age, gender = Gender, height = Height, icu_type = ICUType, admission_weight = Weight)

ts_vars <- sort(setdiff(unique(long$parameter), c("RecordID", "Age", "Gender", "Height", "ICUType")))
all_record_variable <- tidyr::expand_grid(record_id = sort(file_ids), parameter = ts_vars)

ts_summary <- long |>
  filter(parameter %in% ts_vars, !is_descriptor, !is.na(value)) |>
  arrange(record_id, parameter, time_hours, source_row) |>
  group_by(record_id, parameter) |>
  summarise(
    n = n(),
    first = dplyr::first(value),
    last = dplyr::last(value),
    min = min(value),
    max = max(value),
    mean = mean(value),
    n_h00_24 = sum(time_hours < 24),
    n_h24_48 = sum(time_hours >= 24),
    .groups = "drop"
  ) |>
  right_join(all_record_variable, by = c("record_id", "parameter")) |>
  mutate(
    across(c(n, n_h00_24, n_h24_48), ~ replace_na(.x, 0)),
    ever = as.integer(n > 0)
  )

wide_features <- ts_summary |>
  pivot_wider(
    names_from = parameter,
    values_from = c(n, first, last, min, max, mean, n_h00_24, n_h24_48, ever),
    names_glue = "{parameter}_{.value}"
  )

wide <- static |>
  full_join(wide_features, by = "record_id") |>
  left_join(outcomes, by = "record_id") |>
  arrange(record_id)

stopifnot(
  "Wide table must have one row per admission" = nrow(wide) == expected_n,
  "Wide table record IDs must be unique" = n_distinct(wide$record_id) == expected_n
)

write_csv(wide, file.path(out_dir, "set-a_wide.csv"), na = "")