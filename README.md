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
conda activate genome-assembly-mt1881
```

## Running the QC workflow

From the repository root (where `scripts/` lives), run:

```bash
bash scripts/workflow.sh
```

This will:
- Run `fastp` on the raw Illumina reads and produce `reads_qc/illumina_1.fastq.gz` and `reads_qc/illumina_2.fastq.gz`.
- Filter the Nanopore reads with `Filtlong` and produce `reads_qc/ont.fastq`.

These three files are the cleaned inputs for the downstream assembly and polishing steps that produced the assemblies and results in the original project directory (`assemblies/`, `autocycler_out/`, `medaka_run1/`, `polypolish/`, `pypolca/`, `quast/`, `quast_analysis/`, `bakta/`, `snippy/).

## Autocycler usage

Initially, the full Autocycler wrapper (`autocycler_full.sh`) was attempted but did not complete successfully on this dataset. Instead, assemblies were generated (for example with Raven), and the Autocycler resume script was used to continue from the existing `assemblies/` folder. [page:1]

- `autocycler_full.sh`: full pipeline wrapper (included here for reference; not used in the final successful run).
- `autocycler_resume.sh`: script that was actually used, starting from `assemblies/` and producing the consensus `autocycler_assembly.fasta`, which was then used for downstream polishing.

## Polishing steps

After obtaining the long-read consensus assembly from Autocycler, a multi-step polishing strategy was applied. [page:1]

### 1. Medaka (ONT-based polishing)

Input and output:

- Input: `autocycler_out/consensus_assembly.fasta` + Nanopore reads (`MT_1881.fastq.gz`, mapped as described below). [page:1]
- Output: `medaka_run1/medaka_polished/consensus.fasta` (long-read–polished assembly, also used under `polypolish/` as `medaka_polished.fasta`).

To polish the Autocycler consensus assembly with Nanopore reads:

1. Set up a working directory:

   ```bash
   cd ~/Documents/terminal
   mkdir medaka_run1
   cd medaka_run1
   ```

2. Map Nanopore reads to the Autocycler consensus and create a sorted BAM:

   ```bash
   minimap2 -ax map-ont -t 4 \
     ../autocycler_out/consensus_assembly.fasta \
     ../MT_1881.fastq.gz | \
     samtools sort -o ont_aligned.bam -

   samtools index ont_aligned.bam
   ```

3. Run Medaka polishing (choose a model appropriate for your basecalling):

   ```bash
   medaka_consensus \
     -i ont_aligned.bam \
     -d ../autocycler_out/consensus_assembly.fasta \
     -o medaka_polished \
     -m r1041_e82_400bps_sup_g632 \
     -t 4
   ```

This produces a long-read–polished assembly at:

- `medaka_polished/consensus.fasta`

### 2. Polypolish (short-read polishing)

From the `polypolish` directory:

```bash
cd ~/Documents/terminal/polypolish
ls -lh medaka_polished.fasta
```

Run BWA-MEM alignments for R1 and R2:

```bash
time bwa mem -t 4 -a medaka_polished.fasta ../reads_qc/illumina_1.fastq.gz > alignments_1.sam

time bwa mem -t 4 -a medaka_polished.fasta ../reads_qc/illumina_2.fastq.gz > alignments_2.sam
```

Filter alignments for Polypolish:

```bash
time polypolish filter \
  --in1 alignments_1.sam --in2 alignments_2.sam \
  --out1 filtered_1.sam --out2 filtered_2.sam
```

Run Polypolish:

```bash
time polypolish polish medaka_polished.fasta \
  filtered_1.sam filtered_2.sam > medaka_polypolish.fasta

ls -lh medaka_polished.fasta medaka_polypolish.fasta
```

This produces `medaka_polypolish.fasta` (~5.2 Mb), the Illumina-polished assembly used as input for the final pypolca polishing step.  

For clarity, the Polypolish output was renamed when preparing PyPolca:

```bash
cd ~/Documents/terminal
mkdir -p pypolca
cd pypolca

cp ../polypolish/medaka_polypolish.fasta .
mv medaka_polypolish.fasta polypolish_polished.fasta

ls -la polypolish_polished.fasta
```

So the structure becomes:

- `terminal/polypolish/` – contains `medaka_polypolish.fasta`  
- `terminal/pypolca/` – contains `polypolish_polished.fasta` (input to PyPolca)  
- `terminal/reads_qc/` – contains cleaned Illumina reads

### 3. PyPolca (final short-read polishing)

A separate environment was created for PyPolca:

```bash
conda create -n pypolca_env -c bioconda -c conda-forge pypolca
conda activate pypolca_env
```

#### Index assembly for PyPolca

From `terminal/pypolca`:

```bash
cd ~/Documents/terminal/pypolca

bwa index polypolish_polished.fasta
ls -la *.bwt  # Confirm indexing
```

Expected:

- `polypolish_polished.fasta`  
- `polypolish_polished.fasta.bwt` (and other BWA index files)

#### BWA-MEM alignment for PyPolca

PyPolca uses primary alignments only (no `-a`):

```bash
time bwa mem -t 8 -T 50 polypolish_polished.fasta \
  ~/Documents/terminal/reads_qc/illumina_1.fastq.gz \
  ~/Documents/terminal/reads_qc/illumina_2.fastq.gz | \
samtools sort -o pypolca.bam - && samtools index pypolca.bam
```

Expected outputs:

- `pypolca.bam`  
- `pypolca.bam.bai`

Check alignment stats:

```bash
samtools flagstat pypolca.bam  # >95% mapped expected
```

In this run, mapping was ~99.9% and properly paired ~99.8%, indicating excellent coverage for polishing.

#### PyPolca polishing – two iterations

PyPolca is driven with the `run` subcommand:

**First iteration:**

```bash
pypolca run -a polypolish_polished.fasta \
  -1 ~/Documents/terminal/reads_qc/illumina_1.fastq.gz \
  -2 ~/Documents/terminal/reads_qc/illumina_2.fastq.gz \
  -t 4 -o pypolca_1
```

Expected:

- `pypolca_1/pypolca_1.fasta` – first PyPolca-polished assembly  
- `pypolca_1/pypolca_1.log` – run statistics

**Second iteration:**

```bash
pypolca run -a pypolca_1/pypolca_1.fasta \
  -1 ~/Documents/terminal/reads_qc/illumina_1.fastq.gz \
  -2 ~/Documents/terminal/reads_qc/illumina_2.fastq.gz \
  -t 4 -o pypolca_final
```

Final outputs:

```bash
ls -la pypolca_1/*.fasta pypolca_final/*.fasta
echo "COMPLETE PIPELINE: Autocycler → Medaka → Polypolish → PyPolca"
```

The final assembly used for downstream QUAST, Bakta and Snippy analyses is:

- `pypolca_final/pypolca_final.fasta`
```

'''Results (QUAST on final assembly)

The final polished assembly (`pypolca_final/pypolca_final.fasta`) was evaluated with QUAST:

- Total contigs (≥ 500 bp): 2
- Total length: 5,409,086 bp
- Largest contig: 5,291,975 bp
- N50 / N90: 5,291,975 bp
- GC content: 50.36%
- L50 / L90: 1
- N's per 100 kbp: 0

These metrics indicate a near-complete, low-fragmentation bacterial genome with two contigs and no ambiguous bases.


Detailed QUAST HTML reports (including Icarus viewers) are available in `quast/quast_results/` (for example, `quast/quast_results/report.html` and `quast/quast_results/icarus.html`) and can be opened locally in a browser after cloning this repository.'''
