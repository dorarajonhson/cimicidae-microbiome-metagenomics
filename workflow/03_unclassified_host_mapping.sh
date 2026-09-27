#!/bin/bash
# Step 3 (optional) - Map unclassified reads against the closest available host genome
#
# Most DNA-derived reads were not classified by Kraken2. To check whether they come from
# the insects themselves, the unclassified read pairs are aligned with BWA-MEM to the
# genome of the common bed bug (Cimex lectularius), the closest relative of bat and swallow
# bugs with a reference genome, and mapping statistics are reported with samtools.
#
# Usage:  bash workflow/03_unclassified_host_mapping.sh <kraken_output_dir> <C_lectularius.fna> <output_dir> [threads]
#   <C_lectularius.fna>: Cimex lectularius reference genome (NCBI RefSeq)

set -euo pipefail

in_dir=${1:?"give the output folder of step 2"}
ref=${2:?"give the Cimex lectularius genome (FASTA)"}
out_dir=${3:?"give the output folder"}
threads=${4:-8}
mkdir -p "${out_dir}"

# index the reference once
if [ ! -f "${ref}.bwt" ]; then
  bwa index "${ref}"
fi

shopt -s nullglob
for r1 in "${in_dir}"/reads/*_unclassified_1.fq.gz; do
  sample=$(basename "${r1}" _unclassified_1.fq.gz)
  r2="${in_dir}/reads/${sample}_unclassified_2.fq.gz"

  bwa mem -t "${threads}" "${ref}" "${r1}" "${r2}" \
    | samtools sort -@ "${threads}" -o "${out_dir}/${sample}.unclassified_vs_Clectularius.bam" -
  samtools index "${out_dir}/${sample}.unclassified_vs_Clectularius.bam"
  samtools flagstat "${out_dir}/${sample}.unclassified_vs_Clectularius.bam" \
    > "${out_dir}/${sample}.flagstat.txt"
done

echo "Host mapping finished: results in ${out_dir}"
