## Discrepancy Investigation Script
## Purpose: Diagnose why generated vs manual banding report row counts differ.
## It attempts to classify missing/extra rows by examining:
##  - Presence in raw input (birds export)
##  - Duplicate handling (multiple records per band)
##  - Year filter issues
##  - Colour band availability
##  - Species mapping (unmapped species dropped?)
##
## Usage: Rscript investigate_banding_report_discrepancies.R 2024

args <- commandArgs(trailingOnly = TRUE)
YEAR <- if (length(args) > 0) as.integer(args[1]) else 2024L

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(stringr)
  library(purrr)
  library(tidyr)
  library(writexl)
})

raw_file <- sprintf("input/birds_eggs_%d.xlsx", YEAR)
gen_file <- sprintf("output/Banding-report-kakrarahu-%d.xlsx", YEAR)
man_file <- sprintf("output/Banding-report-kakrarahu-%d-manual.xlsx", YEAR)
stopifnot(file.exists(raw_file), file.exists(gen_file), file.exists(man_file))

sheets <- c("New rings", "Plastic rings seen bird trapped")
read_rep <- function(path){
  setNames(lapply(sheets, function(s) read_excel(path, sheet = s, guess_max = 5000)), sheets)
}
manual <- read_rep(man_file)
generated <- read_rep(gen_file)

raw_birds <- read_excel(raw_file, sheet = "birds", guess_max = 6000)

## Helper: robust key detection (ASCII pattern fallback)
find_col <- function(nms, pattern_vec){
  for (p in pattern_vec){
    idx <- which(tolower(nms) == tolower(p))
    if (length(idx)==1) return(nms[idx])
  }
  # fuzzy contains
  for (p in pattern_vec){
    idx <- grep(p, nms, ignore.case = TRUE)
    if (length(idx)==1) return(nms[idx])
  }
  NA_character_
}

## Determine ring letter & number columns in report (manual uses accented Estonian)
get_key_components <- function(df){
  nms <- names(df)
  letters_col <- find_col(nms, c("Rõngakood:tähed", "Rongakood:t\u00e4hed", ":t\u00e4h", ":tah"))
  numbers_col <- find_col(nms, c("Rõngakood:numbrid", "Rongakood:numbrid", ":num"))
  color_col   <- find_col(nms, c("Värvirõnga kood", "Varviro", "ringa kood", "kood"))
  list(letters=letters_col, numbers=numbers_col, colour=color_col)
}

extract_keys <- function(df, sheet_name){
  kc <- get_key_components(df)
  if (is.na(kc$letters) || is.na(kc$numbers)) return(character(0))
  base <- paste0(df[[kc$letters]], "-", df[[kc$numbers]])
  if (sheet_name == "Plastic rings seen bird trapped" && !is.na(kc$colour) && kc$colour %in% names(df)){
    base <- paste0(base, "|", df[[kc$colour]])
  }
  base
}

man_keys <- lapply(names(manual), function(s) extract_keys(manual[[s]], s))
names(man_keys) <- names(manual)

gen_keys <- lapply(names(generated), function(s) extract_keys(generated[[s]], s))
names(gen_keys) <- names(generated)

## Summaries
summary_df <- tibble(
  sheet = sheets,
  manual_rows = sapply(manual, nrow),
  generated_rows = sapply(generated, nrow),
  diff = generated_rows - manual_rows,
  manual_unique_keys = sapply(man_keys, function(k) length(unique(k))),
  generated_unique_keys = sapply(gen_keys, function(k) length(unique(k)))
)
print(summary_df)

## Row classification: missing / extra keys
classify <- function(sheet){
  mk <- unique(man_keys[[sheet]])
  gk <- unique(gen_keys[[sheet]])
  list(missing = setdiff(mk, gk), extra = setdiff(gk, mk))
}

miss_extra <- setNames(lapply(sheets, classify), sheets)

## Function to parse key back to parts
split_key <- function(keys){
  tibble(key = keys) %>%
    separate(key, into = c("ring", "maybe_colour"), sep = "\\|", fill = "right") %>%
    separate(ring, into = c("letters","numbers"), sep = "-", fill = "right")
}

## Examine raw duplication counts per band
raw_split <- raw_birds %>% mutate(ring_letters = str_extract(band, "^[A-Za-z]+"), ring_numbers = str_extract(band, "[0-9]+$"))
raw_band_counts <- raw_split %>% count(ring_letters, ring_numbers, name = "raw_records")

## For NEW rings: Are missing manual keys due to year filtering or species mapping?
analysis_new <- {
  miss_new <- miss_extra[["New rings"]]$missing
  extra_new <- miss_extra[["New rings"]]$extra
  miss_df <- split_key(miss_new)
  extra_df <- split_key(extra_new)
  miss_join <- miss_df %>% left_join(raw_band_counts, by = c("letters" = "ring_letters", "numbers" = "ring_numbers"))
  extra_join <- extra_df %>% left_join(raw_band_counts, by = c("letters" = "ring_letters", "numbers" = "ring_numbers"))
  list(missing=miss_join, extra=extra_join)
}

## For SEEN rings: Evaluate colour presence in raw and whether band exists
colour_present <- raw_split %>% mutate(colour_present = !is.na(color_band)) %>% 
  group_by(ring_letters, ring_numbers) %>% summarise(any_colour = any(colour_present), .groups='drop')
analysis_seen <- {
  miss_seen <- miss_extra[["Plastic rings seen bird trapped"]]$missing
  extra_seen <- miss_extra[["Plastic rings seen bird trapped"]]$extra
  miss_df <- split_key(miss_seen)
  extra_df <- split_key(extra_seen)
  miss_join <- miss_df %>% left_join(colour_present, by = c("letters" = "ring_letters", "numbers" = "ring_numbers"))
  extra_join <- extra_df %>% left_join(colour_present, by = c("letters" = "ring_letters", "numbers" = "ring_numbers"))
  list(missing=miss_join, extra=extra_join)
}

## Potential reasons inference
infer_reasons_new <- function(miss_tbl){
  miss_tbl %>% mutate(reason = case_when(
    is.na(raw_records) ~ "Not in raw export",
    raw_records > 1 ~ "Multiple raw rows (dedup removed some)",
    TRUE ~ "Check species/year filter"
  ))
}

infer_reasons_seen <- function(tbl){
  tbl %>% mutate(reason = case_when(
    is.na(any_colour) ~ "Band w/o colour in raw (manual added?)",
    any_colour == FALSE ~ "No colour band events in raw",
    TRUE ~ "Check duplicate / filtering logic"
  ))
}

new_missing_reasoned <- infer_reasons_new(analysis_new$missing)
seen_missing_reasoned <- infer_reasons_seen(analysis_seen$missing)

## Output directory
out_dir <- sprintf("output/discrepancy_analysis_%d", YEAR)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(summary_df, file.path(out_dir, "summary_counts.csv"), row.names = FALSE)
write.csv(new_missing_reasoned, file.path(out_dir, "new_missing.csv"), row.names = FALSE)
write.csv(analysis_new$extra, file.path(out_dir, "new_extra.csv"), row.names = FALSE)
write.csv(seen_missing_reasoned, file.path(out_dir, "seen_missing.csv"), row.names = FALSE)
write.csv(analysis_seen$extra, file.path(out_dir, "seen_extra.csv"), row.names = FALSE)

## Consolidated Excel workbook
excel_path <- file.path(out_dir, sprintf("discrepancy_tables_%d.xlsx", YEAR))
write_xlsx(list(
  summary = summary_df,
  new_missing = new_missing_reasoned,
  new_extra = analysis_new$extra,
  seen_missing = seen_missing_reasoned,
  seen_extra = analysis_seen$extra
), path = excel_path)

cat("Excel discrepancy workbook written:", excel_path, "\n")

cat("Discrepancy investigation complete. See:", out_dir, "\n")
