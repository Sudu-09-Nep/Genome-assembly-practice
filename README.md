# Genome assembly practice (Perfect-bacterial-genome-tutorial based)

## Goal
Practice hybrid bacterial genome assembly using ONT + Illumina reads, following rrwick/Perfect-bacterial-genome-tutorial with extra tools (Flye, Filtlong, Raven, Autocycler).

## Data
- Long reads: ont.fastq (subsampled)
- Short reads: illumina_1.fastq.gz, illumina_2.fastq.gz
- Raw data source: SSSIHL Depertment of Biosciences AMR lab

## Tools used at different level
- Filtlong,fastq 
- Flye,Raven,Autocycler 
- Polypolish, Medaka, pypolca
- QUAST, Bakta, Snippy

## Workflow overview
1. Read QC and subsampling.
2. Long-read assembly (Flye/Raven/Autocycler).
3. Polishing with Illumina and ONT.
4. Assembly evaluation (QUAST) and annotation (Bakta).
5. Variant calling (Snippy).

## How to reproduce
- Create Conda env from `environment.yml` (to be added).
- Run commands in `scripts/` (to be added).

