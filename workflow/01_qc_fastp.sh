#!/bin/bash
# Step 1 - Quality control of MGISEQ-200 paired-end reads (PE100) with fastp v0.23.2
#
# fastp is run with its default settings, as in the manuscript:
#   - automatic adapter trimming
#   - reads with more than 40% low-quality bases (Phred < 15) are removed
#   - reads shorter than 15 bp after trimming are removed
# Libraries sequenced on more than one index/lane are concatenated first
# (e.g. one library sequenced on two indexes).
#
# Usage:  bash workflow/01_qc_fastp.sh <samplesheet.tsv> <raw_fastq_dir> <output_dir> [threads]
#   samplesheet.tsv: tab-separated, header "sample_id  fastq_1  fastq_2";
#   several files for one library are comma-separated (see data/samplesheet_template.tsv).
# Raw files are never modified or deleted.

set -euo pipefail

sheet=${1:?"give the samplesheet"}
raw_dir=${2:?"give the folder with raw FASTQ files"}
out_dir=${3:?"give the output folder"}
threads=${4:-8}

mkdir -p "${out_dir}/reports" "${out_dir}/merged"
: > "${out_dir}/trimmed_fastq_checksums.md5"

tail -n +2 "${sheet}" | while IFS=$'\t' read -r sample r1_list r2_list || [ -n "${sample}" ]; do
  [ -z "${sample}" ] && continue

  # join the files of the same library (a single file is simply copied through)
  r1="${out_dir}/merged/${sample}_1.fq.gz"
  r2="${out_dir}/merged/${sample}_2.fq.gz"
  : > "${r1}"; : > "${r2}"
  IFS=',' read -ra f1 <<< "${r1_list}"
  IFS=',' read -ra f2 <<< "${r2_list}"
  if [ ${#f1[@]} -ne ${#f2[@]} ]; then
    echo "Unequal number of R1 and R2 files for ${sample}" >&2
    exit 1
  fi
  for f in "${f1[@]}"; do cat "${raw_dir}/${f}" >> "${r1}"; done
  for f in "${f2[@]}"; do cat "${raw_dir}/${f}" >> "${r2}"; done

  fastp \
    -i "${r1}" -I "${r2}" \
    -o "${out_dir}/${sample}_1.fastp.fq.gz" \
    -O "${out_dir}/${sample}_2.fastp.fq.gz" \
    --thread "${threads}" \
    --html "${out_dir}/reports/${sample}.fastp.html" \
    --json "${out_dir}/reports/${sample}.fastp.json"

  md5sum "${out_dir}/${sample}_1.fastp.fq.gz" "${out_dir}/${sample}_2.fastp.fq.gz" \
    >> "${out_dir}/trimmed_fastq_checksums.md5"
  rm "${r1}" "${r2}"   # merged copies only; raw files are kept
done

echo "fastp finished: results in ${out_dir}"
