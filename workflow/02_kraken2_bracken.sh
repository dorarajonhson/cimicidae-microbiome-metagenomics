#!/bin/bash
# Step 2 - Taxonomic classification (Kraken2) and abundance re-estimation (Bracken)
#
# The published analysis ran both tools on the Galaxy platform (usegalaxy.org):
#   Kraken2 2.17.1 (Galaxy tool kraken2/2.17.1+galaxy0), database k2_standard_20210517
#   Bracken 3.1    (Galaxy tool bracken/est_abundance/3.1+galaxy0), k-mer distribution
#                  k2_standard_20210517, read length 100
# This script runs the same commands with the same parameters outside Galaxy.
#
# Kraken2:  --confidence 0.1 --minimum-base-quality 0 --minimum-hit-groups 2
#           --use-names, report written per sample, classified/unclassified reads split
# Bracken:  levels P (phylum) and S (species), threshold -t 10
#
# Usage:  bash workflow/02_kraken2_bracken.sh <fastp_dir> <kraken2_db_dir> <output_dir> [threads]
#   <kraken2_db_dir>: the Kraken2 standard database, release 2021-05-17
#     (https://benlangmead.github.io/aws-indexes/k2), including database100mers.kmer_distrib

set -euo pipefail

in_dir=${1:?"give the fastp output folder"}
db=${2:?"give the Kraken2 database folder"}
out_dir=${3:?"give the output folder"}
threads=${4:-8}

mkdir -p "${out_dir}/kraken2" "${out_dir}/bracken" "${out_dir}/reads"

shopt -s nullglob
r1_files=("${in_dir}"/*_1.fastp.fq.gz)
if [ ${#r1_files[@]} -eq 0 ]; then
  echo "No *_1.fastp.fq.gz files found in ${in_dir}" >&2
  exit 1
fi

for r1 in "${r1_files[@]}"; do
  sample=$(basename "${r1}" _1.fastp.fq.gz)
  r2="${in_dir}/${sample}_2.fastp.fq.gz"

  kraken2 \
    --db "${db}" \
    --threads "${threads}" \
    --paired "${r1}" "${r2}" \
    --confidence 0.1 \
    --minimum-base-quality 0 \
    --minimum-hit-groups 2 \
    --use-names \
    --report "${out_dir}/kraken2/${sample}.kreport" \
    --classified-out "${out_dir}/reads/${sample}_classified#.fq" \
    --unclassified-out "${out_dir}/reads/${sample}_unclassified#.fq" \
    > "${out_dir}/kraken2/${sample}.kraken"

  gzip -f "${out_dir}/reads/${sample}"_*classified_?.fq

  for level in P S; do
    est_abundance.py \
      -i "${out_dir}/kraken2/${sample}.kreport" \
      -k "${db}/database100mers.kmer_distrib" \
      -l "${level}" \
      -t 10 \
      -o "${out_dir}/bracken/${sample}.bracken_${level}.tsv" \
      --out-report "${out_dir}/bracken/${sample}.bracken_${level}.kreport"
  done
done

echo "Kraken2/Bracken finished: results in ${out_dir}"
