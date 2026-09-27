# Step 4 - Combine per-sample Bracken outputs into count tables
#
# Reads <sample>.bracken_P.tsv and <sample>.bracken_S.tsv from step 2 and writes
# phylum- and species-level tables of Bracken-estimated read counts
# (rows = taxa, columns = samples), the input of the analysis notebook.
#
# Usage:  Rscript workflow/04_build_count_tables.R <bracken_dir> <output_dir>

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("Usage: Rscript 04_build_count_tables.R <bracken_dir> <output_dir>")
in_dir  <- args[1]
out_dir <- args[2]
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

combine_level <- function(level, out_name) {
  files <- sort(list.files(in_dir, pattern = sprintf("\\.bracken_%s\\.tsv$", level), full.names = TRUE))
  if (length(files) == 0) stop("No Bracken files for level ", level, " in ", in_dir)
  samples <- sub(sprintf("\\.bracken_%s\\.tsv$", level), "", basename(files))

  tabs <- lapply(files, function(f) {
    b <- read.delim(f, check.names = FALSE, stringsAsFactors = FALSE, quote = "")
    setNames(b$new_est_reads, b$name)
  })
  taxa <- sort(unique(unlist(lapply(tabs, names))))
  mat <- sapply(tabs, function(x) { v <- x[taxa]; v[is.na(v)] <- 0; v })
  mat <- matrix(mat, nrow = length(taxa), dimnames = list(taxa, samples))

  write.csv(data.frame(taxon = rownames(mat), mat, check.names = FALSE),
            file.path(out_dir, out_name), row.names = FALSE)
  message(sprintf("%s: %d taxa x %d samples", out_name, nrow(mat), ncol(mat)))
}

combine_level("P", "bracken_phylum_counts.csv")
combine_level("S", "bracken_species_counts.csv")
