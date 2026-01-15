#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# 1. Quality control and filtering
# Goal: clean Illumina and Nanopore reads before assembly
#
# Usage:
#   bash scripts/workflow.sh
###############################################################################

# Make QC folder
mkdir -p reads_qc

# 1.1 Short reads (Illumina) QC with fastp
fastp \
  --in1 MT_2025_01881_S75_L001_R1_001.fastq.gz \
  --in2 MT_2025_01881_S75_L001_R2_001.fastq.gz \
  --out1 reads_qc/illumina_1.fastq.gz \
  --out2 reads_qc/illumina_2.fastq.gz \
  --unpaired1 reads_qc/illumina_u.fastq.gz \
  --unpaired2 reads_qc/illumina_u.fastq.gz

# Remove unpaired reads file (usually small and not needed)
rm -f reads_qc/illumina_u.fastq.gz

# 1.2 Long reads (ONT) filtering with Filtlong
# 1) Remove short ONT reads (< 6 kbp)
filtlong --min_length 6000 MT_1881.fastq.gz > reads_qc/ont_6k.fastq

# 2) Keep the best 90% of bases (drop worst 10%)
filtlong --keep_percent 90 reads_qc/ont_6k.fastq > reads_qc/ont.fastq

# 3) Remove intermediate file
rm -f reads_qc/ont_6k.fastq

# After this step, main inputs for assembly:
# - reads_qc/illumina_1.fastq.gz
# - reads_qc/illumina_2.fastq.gz
# - reads_qc/ont.fastq

