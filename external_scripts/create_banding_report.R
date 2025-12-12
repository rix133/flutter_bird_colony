## Banding report generator
## -------------------------------------------------------------
## This script converts raw export (sheet "birds") from the local
## database (file pattern input/birds_eggs_<YEAR>.xlsx) into an
## official banding Excel report containing two sheets:
##   1. "New rings"  (freshly ringed birds in the season)
##   2. "Plastic rings seen bird trapped" (previously ringed birds seen/trapped, i.e. birds with colour bands)
## The output column structure (57 columns) must match the official
## template exactly. Columns not derivable from input are filled with NA.
##
## -------------------- IMPORTANT ASSUMPTIONS --------------------
## 1. Species mapping: input species "Common Gull" -> output code "lar can".
##    (Add to species_map below if more species appear; for chicks of other
##     species provide the correct 3+3 code, e.g. Eurasian Oystercatcher -> "hae ost").
## 2. New rings definition: first occurrence of each metal ring (band) in the
##    given year (nest_year == target year). We keep ONE row per unique band.
## 3. Seen (plastic) rings: birds with a non-NA colour band (color_band column)
##    and species mapped. We keep one row per unique combination of band + color_band.
## 4. Ring code format: band like "E54072" -> letters = leading non-digits ("E"),
##    numbers = trailing digits (54072). If multiple letters exist (e.g. "UA23264"),
##    letters part is everything until first digit.
## 5. Names: column 'responsible' is split into first (Eesnimi) and last token (Perek.nimi).
##    If only one token present it is treated as first name; surname set to NA.
## 6. Location / coordinates constant for dataset: "Kakrarahud, Läänemaa", lat 58.8, lon 23.4.
## 7. Sex mapping: "Female" -> "f"; "Male" -> "m"; others / NA left NA.
## 8. Age: use age_years as provided (numeric). If NA -> NA.
## 9. Notes:
##    - New rings: "Ringed by: <Full Responsible Name>".
##    - Seen rings: concatenated measurement notes present among:
##        Gland size_mm, Head size_mm, Sex_, Note_ (original free text), each
##        formatted as "Gland size: X mm" / "Head size: X mm" / "Sex: f" / note text.
##      Joined by "; ". If none available -> NA.
## 10. Date column (Kuupäev): uses ringed_date (converted to Date).
## 11. Colour band output value: prefix "LB:W " + color band code (example matches provided output).
## 12. Time (Kellaaeg) not tracked -> NA.
## 13. Any change in official template column names requires updating col_order vector.
## ----------------------------------------------------------------
## If any of these assumptions are incorrect, please adjust the mapping
## section below or let the script author know.

suppressPackageStartupMessages({
    library(readxl)
    library(dplyr)
    library(stringr)
    library(writexl)
    library(tidyr)
    library(purrr)
})

## Parameters -----------------------------------------------------
target_year <- 2025

input_file  <- sprintf("input/birds_eggs_%d.xlsx", target_year)
output_file <- sprintf("output/Banding-report-kakrarahu-%d.xlsx", target_year)

## Read input -----------------------------------------------------
birds <- read_excel(input_file, sheet = "birds", guess_max = 5000)

## Normalise input schema (accept extra or missing columns) -------
required_base_cols <- c(
    "species","ringed_date","Sex_","nest_year","band","color_band","nest",
    "age_years","responsible","Gland size_mm","Head size_mm","Note_"
)
missing_incoming <- setdiff(required_base_cols, names(birds))
if (length(missing_incoming)) {
    for (mc in missing_incoming) birds[[mc]] <- NA
}
## Allow downstream code to rely on presence (values may be NA)


## Helpers --------------------------------------------------------
species_map <- c(
  "Caspian tern" = "hydr casp",
  "Great Cormorant" = "pha car",
  "Mute Swan" = "cyg olo",
  "Common Gull" = "lar can",
  "Common Ringed Plover" = "cha hia",
  "Bar-headed goose" = "ans ind",
  "Little tern" = "stern alb",
  "Lesser Black-backed Gull" = "lar fus",
  "Great Black-backed Gull" = "lar mar",
  "Arctic Tern" = "ste aea",
  "Little Gull" = "hyd min",
  "Goosander" = "mer mer",
  "Common Tern" = "ste hir",
  "Red breasted merganser" = "mer ser",
  "Sandwich tern" = "thal sand",
  "Greylag goose" = "ans ans",
  "European Herring Gull" = "lar arg",
  "Tufted duck" = "Ayt Ful",
  "Mallard" = "ana pla",
  "Eurasian Oystercatcher" = "hae ost",
  "Black-Headed Gull" = "lar rid"
    # Add more mappings as needed, 
)

map_species_code <- function(x) {
    out <- unname(species_map[x])
    out[is.na(out)] <- NA_character_
    out
}

split_ring <- function(band) {
    letters_part <- str_extract(band, "^[A-Za-z]+")
    number_part  <- str_extract(band, "[0-9]+$")
    tibble(letter = letters_part, number = suppressWarnings(as.numeric(number_part)))
}

split_name <- function(x) {
    x <- coalesce(x, "")
    parts <- str_split(x, "\\s+", simplify = TRUE)
    if (ncol(parts) == 0) return(tibble(first = NA_character_, last = NA_character_))
    first <- parts[,1]
    last  <- ifelse(ncol(parts) > 1, parts[,ncol(parts)], NA_character_)
    tibble(first = ifelse(first == "", NA, first), last = last)
}

map_sex <- function(x) {
    dplyr::case_when(
        is.na(x) ~ NA_character_,
        str_to_lower(x) %in% c("female", "f") ~ "f",
        str_to_lower(x) %in% c("male", "m") ~ "m",
        TRUE ~ NA_character_
    )
}

## Standardised columns list (official order) ---------------------
col_order <- c(
    "Eesnimi","Perek.nimi","Rõngakood:tähed","Rõngakood:numbrid","Liik","Sugu","Vanus","Asukoht","Laius","Pikkus","Kuupäev","Kellaaeg","Muud märgised","Metallrõnga info","Värvirõnga kood","Pesakonna suurus","Poja vanus","Poja vanuse täpsus","Püügimeetod","Meelitusvahend","Kasti/võrgu/pesa nr","Staatus","Tiiva pikkus","Mass","Rasvasus","Rasvasusskaala","Jooksme pikkus","Jooksme pikkuse meetod","Noka pikkus","Noka pikkuse meetod","Pea üldpikkus","Tagaküünise pikkus","Sulestiku kood","Sulgimine","Laba-hoosulgede sulgimine","3. laba-hoosule pikkus","Laba-hoosule tipu seisund","Saba pikkus","Sabasulgede vahe","Karpaalhoosulg","Vanad kattesuled","Haudelaik","Nukktiib","Rinnalihas","Soomääramismeetod","Biotoop","Märkused","Korduspüügid","Teise labahoosule siseserva kõverdumine (notch)","[Document Studio] File Status","[Document Studio] Email Status","Merged Doc ID - Taasleiuteade Test 1","Merged Doc URL - Taasleiuteade Test 1","Link to merged Doc - Taasleiuteade Test 1...54","Document Merge Status - Taasleiuteade Test 1...55","Link to merged Doc - Taasleiuteade Test 1...56","Document Merge Status - Taasleiuteade Test 1...57"
)

## Base transformations (add derived fields) ----------------------
birds_base <- birds %>%
    mutate(
        species_code = map_species_code(species),
        ring_date = as.Date(ringed_date),
        sex_code = map_sex(Sex_),
        year_flag = nest_year == target_year
    )

## NEW RINGS ------------------------------------------------------
## First occurrence per band within target year
new_rings_raw <- birds_base %>%
    filter(year_flag) %>%
    arrange(ring_date) %>%
    group_by(band) %>%
    slice_head(n = 1) %>%
    ungroup()

## Split ring & names
new_ring_split  <- split_ring(new_rings_raw$band)
new_name_split  <- split_name(new_rings_raw$responsible)

new_rings <- new_rings_raw %>%
    bind_cols(new_ring_split, new_name_split) %>%
    transmute(
        `Eesnimi` = first,
        `Perek.nimi` = last,
        `Rõngakood:tähed` = letter,
        `Rõngakood:numbrid` = number,
        `Liik` = species_code,
        `Sugu` = sex_code,  # very rarely known at ringing time
        `Vanus` = age_years,
        `Asukoht` = "Kakrarahud, Läänemaa",
        `Laius` = 58.8,
        `Pikkus` = 23.4,
        `Kuupäev` = ring_date,
        `Kellaaeg` = NA,  # not tracked
        `Muud märgised` = NA,
        `Metallrõnga info` = NA,
        `Värvirõnga kood` = NA, # new ring, colour band not yet (or unknown)
        `Pesakonna suurus` = NA,
        `Poja vanus` = NA,
        `Poja vanuse täpsus` = NA,
        `Püügimeetod` = NA,
        `Meelitusvahend` = NA,
        `Kasti/võrgu/pesa nr` = nest,
        `Staatus` = NA,
        `Tiiva pikkus` = NA,
        `Mass` = NA,
        `Rasvasus` = NA,
        `Rasvasusskaala` = NA,
        `Jooksme pikkus` = NA,
        `Jooksme pikkuse meetod` = NA,
        `Noka pikkus` = NA,
        `Noka pikkuse meetod` = NA,
    `Pea üldpikkus` = `Head size_mm`,
        `Tagaküünise pikkus` = NA,
        `Sulestiku kood` = NA,
        `Sulgimine` = NA,
        `Laba-hoosulgede sulgimine` = NA,
        `3. laba-hoosule pikkus` = NA,
        `Laba-hoosule tipu seisund` = NA,
        `Saba pikkus` = NA,
        `Sabasulgede vahe` = NA,
        `Karpaalhoosulg` = NA,
        `Vanad kattesuled` = NA,
        `Haudelaik` = NA,
        `Nukktiib` = NA,
        `Rinnalihas` = NA,
        `Soomääramismeetod` = NA,
        `Biotoop` = NA,
        `Märkused` = paste0("Ringed by: ", responsible),
        `Korduspüügid` = NA,
        `Teise labahoosule siseserva kõverdumine (notch)` = NA,
        `[Document Studio] File Status` = NA,
        `[Document Studio] Email Status` = NA,
        `Merged Doc ID - Taasleiuteade Test 1` = NA,
        `Merged Doc URL - Taasleiuteade Test 1` = NA,
        `Link to merged Doc - Taasleiuteade Test 1...54` = NA,
        `Document Merge Status - Taasleiuteade Test 1...55` = NA,
        `Link to merged Doc - Taasleiuteade Test 1...56` = NA,
        `Document Merge Status - Taasleiuteade Test 1...57` = NA
    ) %>%
    select(all_of(col_order))

## SEEN COLOUR RINGS ----------------------------------------------
seen_raw <- birds_base %>%
    filter(!is.na(color_band)) %>%
    arrange(ring_date) %>%
    group_by(band, color_band) %>%
    slice_head(n = 1) %>%
    ungroup()

seen_split <- split_ring(seen_raw$band)
seen_name_split <- split_name(seen_raw$responsible)

build_seen_notes <- function(df) {
    g <- df[["Gland size_mm"]]; if (is.null(g)) g <- rep(NA, nrow(df))
    h <- df[["Head size_mm"]]; if (is.null(h)) h <- rep(NA, nrow(df))
    s <- df[["Sex_"]]; if (is.null(s)) s <- rep(NA, nrow(df))
    n <- df[["Note_"]]; if (is.null(n)) n <- rep(NA, nrow(df))
    purrr::pmap_chr(list(g, h, s, n), function(gland, head, sex, note_text) {
        parts <- c(
            if (!is.na(gland)) sprintf("Gland size: %s mm", gland) else NULL,
            if (!is.na(head)) sprintf("Head size: %s mm", head) else NULL,
            if (!is.na(sex)) sprintf("Sex: %s", map_sex(sex)) else NULL,
            if (!is.na(note_text)) note_text else NULL
        )
        if (length(parts) == 0) NA_character_ else paste(parts, collapse = "; ")
    })
}

seen_notes <- build_seen_notes(seen_raw)

seen_rings <- seen_raw %>%
    bind_cols(seen_split, seen_name_split) %>%
    mutate(sex_code = map_sex(Sex_)) %>%
    transmute(
        `Eesnimi` = first,
        `Perek.nimi` = last,
        `Rõngakood:tähed` = letter,
        `Rõngakood:numbrid` = number,
        `Liik` = species_code,
        `Sugu` = sex_code,
        `Vanus` = age_years,
        `Asukoht` = "Kakrarahud, Läänemaa",
        `Laius` = 58.8,
        `Pikkus` = 23.4,
        `Kuupäev` = as.Date(ringed_date),
        `Kellaaeg` = NA,
        `Muud märgised` = NA,
        `Metallrõnga info` = NA,
        `Värvirõnga kood` = paste0("LB:W ", color_band),
        `Pesakonna suurus` = NA,
        `Poja vanus` = NA,
        `Poja vanuse täpsus` = NA,
        `Püügimeetod` = NA,
        `Meelitusvahend` = NA,
        `Kasti/võrgu/pesa nr` = nest,
        `Staatus` = NA,
        `Tiiva pikkus` = NA,
        `Mass` = NA,
        `Rasvasus` = NA,
        `Rasvasusskaala` = NA,
        `Jooksme pikkus` = NA,
        `Jooksme pikkuse meetod` = NA,
        `Noka pikkus` = NA,
        `Noka pikkuse meetod` = NA,
    `Pea üldpikkus` = `Head size_mm`,
        `Tagaküünise pikkus` = NA,
        `Sulestiku kood` = NA,
        `Sulgimine` = NA,
        `Laba-hoosulgede sulgimine` = NA,
        `3. laba-hoosule pikkus` = NA,
        `Laba-hoosule tipu seisund` = NA,
        `Saba pikkus` = NA,
        `Sabasulgede vahe` = NA,
        `Karpaalhoosulg` = NA,
        `Vanad kattesuled` = NA,
        `Haudelaik` = NA,
        `Nukktiib` = NA,
        `Rinnalihas` = NA,
        `Soomääramismeetod` = NA,
        `Biotoop` = NA,
        `Märkused` = seen_notes,
        `Korduspüügid` = NA,
        `Teise labahoosule siseserva kõverdumine (notch)` = NA,
        `[Document Studio] File Status` = NA,
        `[Document Studio] Email Status` = NA,
        `Merged Doc ID - Taasleiuteade Test 1` = NA,
        `Merged Doc URL - Taasleiuteade Test 1` = NA,
        `Link to merged Doc - Taasleiuteade Test 1...54` = NA,
        `Document Merge Status - Taasleiuteade Test 1...55` = NA,
        `Link to merged Doc - Taasleiuteade Test 1...56` = NA,
        `Document Merge Status - Taasleiuteade Test 1...57` = NA
    ) %>%
    select(all_of(col_order))

## Ensure all columns exist even if empty (safety) -----------------
ensure_cols <- function(df) {
    missing <- setdiff(col_order, names(df))
    for (m in missing) df[[m]] <- NA
    df[col_order]
}
new_rings <- ensure_cols(new_rings)
seen_rings <- ensure_cols(seen_rings)

## Write output ----------------------------------------------------
dir.create(dirname(output_file), showWarnings = FALSE, recursive = TRUE)
write_xlsx(list(
    `New rings` = new_rings,
    `Plastic rings seen bird trapped` = seen_rings
), path = output_file)

message("Report written: ", output_file)

## End of script --------------------------------------------------