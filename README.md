# Genome assembly practice (Perfect-bacterial-genome-tutorial based)

## Goal
Practice hybrid bacterial genome assembly using ONT + Illumina reads, following rrwick/Perfect-bacterial-genome-tutorial and applying it to an MT1881 isolate.

## Data
- Long reads: MT_1881.fastq.gz (Nanopore; filtered to `reads_qc/ont.fastq` by this pipeline).
- Short reads: MT_2025_01881_S75_L001_R1_001.fastq.gz, MT_2025_01881_S75_L001_R2_001.fastq.gz (Illumina; cleaned to `reads_qc/illumina_1.fastq.gz`, `reads_qc/illumina_2.fastq.gz`).
- Raw data source: SSSIHL Department of Biosciences, AMR lab.

## Tools used
- Read QC and filtering: `fastp`, `Filtlong`.
- Long-read assembly: `Flye`, `Raven`, `Autocycler`.
- Polishing: `Medaka`, `Polypolish`, `pypolca`.
- Evaluation and annotation: `QUAST`, `Bakta`.
- Variant calling: `Snippy`.

## Setup

Create and activate the Conda environment defined in this repository:

```bash
conda env create -f environment.yml
conda activate environment name
