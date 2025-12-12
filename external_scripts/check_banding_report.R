## Simplified ASCII-only validation script
args <- commandArgs(trailingOnly = TRUE)
year <- if (length(args) > 0) as.integer(args[1]) else 2024L
gen_file <- sprintf("output/Banding-report-kakrarahu-%d.xlsx", year)
man_file <- sprintf("output/Banding-report-kakrarahu-%d-manual.xlsx", year)
stopifnot(file.exists(gen_file), file.exists(man_file))
library(readxl)
sheets <- c("New rings", "Plastic rings seen bird trapped")
read_all <- function(f) { lapply(sheets, function(s) read_excel(f, sheet = s, guess_max = 5000)) }
gen <- read_all(gen_file); names(gen) <- sheets
man <- read_all(man_file); names(man) <- sheets
row_counts <- data.frame(sheet = sheets, generated = sapply(gen, nrow), manual = sapply(man, nrow))
row_counts$diff <- row_counts$generated - row_counts$manual
print(row_counts)
build_key <- function(df, sheet_name){
	nms <- names(df)
	letters_col <- grep(":t", nms, fixed = TRUE)[1]
	numbers_col <- grep(":num", nms, fixed = TRUE)[1]
	colour_col  <- grep("kood", nms, fixed = TRUE)[1]
	if (is.na(letters_col) || is.na(numbers_col)) return(seq_len(nrow(df)))
	key <- paste0(df[[letters_col]], "-", df[[numbers_col]])
	if (sheet_name == "Plastic rings seen bird trapped" && !is.na(colour_col)) key <- paste0(key, "|", df[[colour_col]])
	key
}
for (s in sheets){
	gk <- build_key(gen[[s]], s); mk <- build_key(man[[s]], s)
	miss <- setdiff(mk, gk); extra <- setdiff(gk, mk)
	cat("\nSheet:", s, "\n  Missing in generated:", length(miss), "\n  Extra in generated:", length(extra), "\n")
	if (length(miss)>0) cat("   First missing:", paste(head(miss,10), collapse=", "), "\n")
	if (length(extra)>0) cat("   First extra:", paste(head(extra,10), collapse=", "), "\n")
}
cat("\nValidation done.\n")
