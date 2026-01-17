# Genome Assembly Practice Project

## Project Overview

This repository documents a **hands-on genome assembly and polishing workflow** developed as a practice and learning project using real sequencing data. The goal is to perform **end-to-end bacterial genome assembly**, starting from raw Oxford Nanopore and Illumina reads, through quality control, assembly, polishing, variant calling, quality assessment, and annotation.

The project emphasizes:

* Reproducibility
* Comparison of multiple assemblers
* Iterative polishing strategies
* Transparent documentation of intermediate and final results

This repository is structured to resemble a **small, self-contained research project** rather than a raw working directory.

---

## Goal of the Project

The main objectives of this project are:

* To assemble a bacterial genome from **real sequencing data**
* To compare assemblies generated using multiple long-read assemblers
* To improve assembly accuracy using **iterative polishing pipelines**
* To assess assembly quality using standard metrics
* To annotate the final polished assembly
* To document the full workflow in a reproducible and inspectable manner

---

## Data Description

This project uses sequencing data provided by a research scholar for practice purposes.

### Input data includes:

* **Oxford Nanopore reads**
* **Illumina paired-end reads**

Raw reads are preserved under the `data/` directory (or excluded via `.gitignore` if large), while processed and subsampled reads are tracked separately to maintain clarity between inputs and derived data.

---

## Software and Tools Used

This workflow integrates widely used tools in bacterial genome assembly and analysis:

* **fastp and filtlong** – read quality control
* **Autocycler** – assembly consensus generation
* **Flye**, **Miniasm**, **Raven**, **NECAT**, **NextDenovo**, etc. – long-read assembly
* **Medaka** – long-read polishing
* **Polypolish** – short-read polishing
* **PyPolCA** – polishing using Illumina reads
* **QUAST** – assembly quality assessment
* **Snippy** – variant calling
* **Bakta** – genome annotation

All tools are installed via Conda to ensure reproducibility.

---

## Environment Setup

A Conda environment is used to manage dependencies.

```bash
conda env create -f environment.yml
conda activate environment_name
```

Tool versions are documented in the environment file.

---

## Workflow Summary

The workflow follows a logical progression from raw reads to final annotated assembly.

### 1. Read Quality Control

* Quality control and filtering using **fastp and filtlong**
* Output includes HTML and JSON QC reports

### 2. Subsampling and Preparation

* Nanopore reads are subsampled to generate multiple datasets
* Enables comparison of assemblies under different coverage conditions

### 3. Genome Assembly

* Assemblies generated using multiple long-read assemblers
* Assemblies are combined and evaluated using **Autocycler**
* Consensus assemblies are produced

### 4. Polishing

Polishing is performed in stages:

* **Medaka** for long-read polishing
* **Polypolish** using Illumina reads
* **PyPolCA** for final correction

### 5. Assembly Quality Assessment

* **QUAST** is used to evaluate:

  * Assembly size
  * N50 / L50
  * GC content
  * Misassemblies

### 6. Variant Calling

* **Snippy** is used to identify variants relative to a reference
* Outputs include VCF, BED, and summary reports

### 7. Genome Annotation

* Final polished assembly annotated using **Bakta**
* Outputs include GFF3, GenBank, TSV, and graphical summaries

---

## Repository Structure

The repository is organized to separate inputs, methods, outputs, and documentation:

```text
data/        # Raw and intermediate data
scripts/     # Executable workflow scripts
results/     # Final assemblies, QC, variants, annotation
docs/        # Workflow summaries and interpretation
```

This structure mirrors best practices used in research-grade bioinformatics projects.

---

## Results Overview

Key outputs of this project include:

* Final polished genome assemblies (FASTA)
* Assembly quality reports (QUAST)
* Variant call sets (Snippy)
* Fully annotated genome (Bakta)

Detailed outputs are available under the `results/` directory.

---

## Reproducibility Notes

* All commands used in the analysis are preserved in scripts
* Software versions are controlled via Conda
* Intermediate files are separated from final results
* Large or auto-generated files are excluded using `.gitignore`

---

## Learning Outcomes

Through this project, I gained practical experience in:

* Handling real sequencing data
* Evaluating multiple genome assembly strategies
* Applying multi-step polishing pipelines
* Interpreting quality metrics
* Structuring bioinformatics projects professionally

---

## Future Improvements

Potential extensions of this project include:

* Comparative analysis against a reference genome
* Structural variant detection
* Visualization of assembly graphs
* Workflow automation using Snakemake or Nextflow

---

## Acknowledgements

The sequencing data used in this project was kindly provided by a research scholar for learning and practice purposes.

---
## Methodological Reference

The overall assembly and polishing strategy used in this project was inspired by
Ryan Wick’s *“Perfect bacterial genome assembly”* guide.

While the workflow here has been adapted for learning purposes and extended with
additional tools and comparisons, the core principles of iterative long-read
assembly, short-read polishing, and rigorous quality assessment follow the best
practices outlined in that guide.

Reference:
- Wick RR. *Perfect bacterial genome assembly*.  
  https://github.com/rrwick/Perfect-bacterial-genome-assembly

## Detailed workflow

For exact commands, directory-level notes, and expected outputs for each step
(QC → assembly → Medaka → Polypolish → PyPolCA → QUAST → Snippy), see:

- `docs/workflow_overview.md`

