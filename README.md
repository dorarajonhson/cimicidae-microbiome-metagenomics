# Microbial communities of bat bugs and swallow bugs: DNA and RNA metagenomics

Analysis workflow for the study of the microbial communities of bat bugs (*Stricticimex parvus*) and swallow bugs (*Paracimex avium*) across life stages, using DNA and RNA shotgun metagenomic sequencing.

> Rajonhson D.M. *et al.* Manuscript under review.

Raw reads: NCBI BioProject [PRJNA1467927](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA1467927)

## Study design

Bugs were field-collected in Thailand. One pooled sample was prepared per host and life stage (female, male, nymph). DNA and total RNA (rRNA-depleted) were extracted from each pool and sequenced on the MGISEQ-200 platform (paired-end 100 bp), giving 12 profiles: 2 hosts × 3 life stages × 2 sequencing types.

The metadata of the 12 profiles are in `data/metadata.csv`.

## Workflow

```
 raw reads (MGISEQ-200, PE100)
        |
 1  fastp v0.23.2, default settings (adapter trimming, reads with >40% bases below Q15
    removed, reads <15 bp removed); lanes of the same library concatenated first
        |
 2  Kraken2 (standard database 2021-05-17; confidence 0.1, minimum hit groups 2)
    Bracken 3.1 (read length 100, threshold 10) at phylum and species level
        |                                   \
 4  count tables (Bracken estimated reads)    3  optional: unclassified reads mapped to the
        |                                        Cimex lectularius genome (BWA-MEM, samtools)
 5  downstream analysis in R
    rarefaction curves, rarefaction, alpha diversity (Shannon, observed species, Pielou),
    Bray-Curtis PCoA (DNA and RNA separately), NMDS (DNA and RNA together),
    PERMANOVA (host + life stage + sequencing type), relative abundance (taxa >1%),
    LEfSe input and plots (LEfSe run in mothur)
```

| Step | Script | Tools |
|---|---|---|
| 1 | `workflow/01_qc_fastp.sh` | fastp 0.23.2 |
| 2 | `workflow/02_kraken2_bracken.sh` | Kraken2, Bracken 3.1 |
| 3 | `workflow/03_unclassified_host_mapping.sh` (optional) | BWA 0.7.17, samtools |
| 4 | `workflow/04_build_count_tables.R` | R |
| 5 | `analysis/cimicidae_microbiome.Rmd` | phyloseq 1.46.0, vegan 2.6-4, ggplot2, mothur 1.44.3 |

> **Note on step 2.** The published classification was run on the Galaxy platform (usegalaxy.org; Kraken2 2.17.1+galaxy0 and Bracken 3.1+galaxy0, database `k2_standard_20210517`). `02_kraken2_bracken.sh` runs the same commands with the same parameters from the command line, so the analysis can be reproduced outside Galaxy.

## Running it

```bash
# 0. environment
conda env create -f environment.yml
conda activate cimicidae-metagenomics

# 1. quality control (see data/samplesheet_template.tsv for the samplesheet format)
bash workflow/01_qc_fastp.sh data/samplesheet.tsv raw work/fastp 8

# 2. classification and abundance estimation
bash workflow/02_kraken2_bracken.sh work/fastp k2_standard_20210517 work/kraken 8

# 3. optional: where do the unclassified reads come from?
bash workflow/03_unclassified_host_mapping.sh work/kraken C_lectularius.fna work/host_mapping 8

# 4. count tables
Rscript workflow/04_build_count_tables.R work/kraken/bracken data

# 5. downstream analysis (figures and tables are written to results/)
Rscript -e 'rmarkdown::render("analysis/cimicidae_microbiome.Rmd")'
```

**Samplesheet.** One line per library with the raw FASTQ names from the BioProject. Libraries sequenced on several indexes are listed comma-separated and concatenated before QC; `data/samplesheet_template.tsv` shows the format. Sample IDs must match `data/metadata.csv` (e.g. `BBF_dna`, `SBN_rna`).

**Database.** Kraken2/Bracken standard database, release 2021-05-17 (https://benlangmead.github.io/aws-indexes/k2), including `database100mers.kmer_distrib`.

**A note on interpretation.** Each host × life stage × sequencing type is a single pooled profile. Diversity comparisons, PERMANOVA and LEfSe therefore describe structure in this dataset and are used for feature discovery, not as replicated tests between biological groups.

## Licence and citation

Code released under the MIT licence (see `CITATION.cff`). Please cite the article once published.

Contact: Dora M. Rajonhson — ORCID [0000-0003-3247-4510](https://orcid.org/0000-0003-3247-4510)
