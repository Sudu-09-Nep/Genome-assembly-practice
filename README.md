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

This installs the main tools used for assembly, polishing, and QC/annotation.

##Running the QC workflow

From the repository root (where scripts/ lives), run:
This will:
bash scripts/workflow.sh

This will:
- Run fastp on the raw Illumina reads and produce reads_qc/illumina_1.fastq.gz and reads_qc/illumina_2.fastq.gz.
- Filter the Nanopore reads with Filtlong and produce reads_qc/ont.fastq.

These three files are the cleaned inputs for the downstream assembly and polishing steps that produced the assemblies and results in the original project directory (assemblies/, autocycler_out/, medaka_run1/, polypolish/, pypolca/, quast/, quast_analysis/, bakta/, snippy/).

##Autocycler usage

Initially, the full Autocycler wrapper (autocycler_full.sh) was attempted but did not complete successfully on this dataset. Instead, assemblies were generated (for example with Raven), and the Autocycler resume script was used to continue from the existing assemblies/ folder.

- autocycler_full.sh: full pipeline wrapper (included here for reference; not used in the final successful run).
- autocycler_resume.sh: script that was actually used, starting from assemblies/ and producing the consensus autocycler_assembly.fasta, which was then used for downstream polishing.

##Polishing steps
After obtaining the long-read consensus assembly from Autocycler, a multi-step polishing strategy was applied:

  1.Medaka (ONT-based polishing)
    Input: autocycler_out/consensus_assembly.fasta + Nanopore reads (MT_1881.fastq.gz, mapped as described below).
    Output: medaka_run1/medaka_polished/consensus.fasta (long-read–polished assembly, also used under polypolish/ as medaka_polished.fasta).

  2.Polypolish (short-read polishing)
    Inputs: polypolish/medaka_polished.fasta + cleaned Illumina reads (reads_qc/illumina_1.fastq.gz, reads_qc/illumina_2.fastq.gz).
    Output: polypolish/polypolish_polished.fasta.

  3.pypolca (final short-read polishing)
    Input: polypolish_polished.fasta.
    Output: pypolca/pypolca_1/pypolca_corrected.fasta (final polished assembly used for QUAST, Bakta, and Snippy analysis).



