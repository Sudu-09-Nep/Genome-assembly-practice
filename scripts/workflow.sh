#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# 1. Quality control and filtering
# Goal: clean Illumina and Nanopore reads before assembly
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

###############################################################################
# 2. Long-read assembly with Autocycler
# Goal: consensus long-read assembly from ONT reads
###############################################################################

# 2.1 (optional) Create and activate Autocycler environment
# Run these once manually when setting up:
# conda create -n autocycler_env -c bioconda \
#   autocycler flye raven-assembler miniasm any2fasta minipolish
# conda activate autocycler_env

# 2.2 Full Autocycler wrapper (from rrwick tutorial) – saved as autocycler_full.sh
# NOTE: This script is kept in the repo for reference; typical run below uses resume.
cat > autocycler_full.sh << 'EOF'
#!/usr/bin/env bash
set -e

# Usage:
#   autocycler_full.sh <read_fastq> <threads> <jobs> [read_type]

reads=$1
threads=$2
jobs=$3
read_type=${4:-ont_r10}
max_time="8h"

if [[ -z "$reads" || -z "$threads" || -z "$jobs" ]]; then
    echo "Usage: $0 <read_fastq> <threads> <jobs> [read_type]" 1>&2
    exit 1
fi
if [[ ! -f "$reads" ]]; then
    echo "Error: Input file '$reads' does not exist." 1>&2
    exit 1
fi
if (( threads > 128 )); then threads=128; fi
case $read_type in
    ont_r9|ont_r10|pacbio_clr|pacbio_hifi) ;;
    *) echo "Error: read_type must be ont_r9, ont_r10, pacbio_clr or pacbio_hifi" 1>&2; exit 1 ;;
esac

genome_size=$(autocycler helper genome_size --reads "$reads" --threads "$threads")

# Step 1: subsample the long-read set into multiple files
autocycler subsample --reads "$reads" --out_dir subsampled_reads --genome_size "$genome_size" 2>> autocycler.stderr

# Step 2: assemble each subsampled file
mkdir -p assemblies
rm -f assemblies/jobs.txt
for assembler in raven myloasm miniasm flye metamdbg necat nextdenovo plassembler canu; do
    for i in 01 02 03 04; do
        echo "autocycler helper $assembler --reads subsampled_reads/sample_$i.fastq --out_prefix assemblies/${assembler}_$i --threads $threads --genome_size $genome_size --read_type $read_type --min_depth_rel 0.1" >> assemblies/jobs.txt
    done
done
set +e
nice -n 19 parallel --jobs "$jobs" --joblog assemblies/joblog.tsv --results assemblies/logs --timeout "$max_time" < assemblies/jobs.txt
set -e

# Give circular contigs from Plassembler extra clustering weight
shopt -s nullglob
for f in assemblies/plassembler*.fasta; do
    sed -i 's/circular=True/circular=True Autocycler_cluster_weight=3/' "$f"
done

# Give contigs from Canu and Flye extra consensus weight
for f in assemblies/canu*.fasta assemblies/flye*.fasta; do
    sed -i 's/^>.*$/& Autocycler_consensus_weight=2/' "$f"
done
shopt -u nullglob

# Remove the subsampled reads to save space
rm subsampled_reads/*.fastq

# Step 3: compress the input assemblies into a unitig graph
autocycler compress -i assemblies -a autocycler_out 2>> autocycler.stderr

# Step 4: cluster the input contigs into putative genomic sequences
autocycler cluster -a autocycler_out 2>> autocycler.stderr

# Steps 5 and 6: trim and resolve each QC-pass cluster
for c in autocycler_out/clustering/qc_pass/cluster_*; do
    autocycler trim -c "$c" 2>> autocycler.stderr
    autocycler resolve -c "$c" 2>> autocycler.stderr
done

# Step 7: combine resolved clusters into a final assembly
autocycler combine -a autocycler_out -i autocycler_out/clustering/qc_pass/cluster_*/5_final.gfa 2>> autocycler.stderr
EOF

chmod +x autocycler_full.sh

# 2.3 Autocycler RESUME script (what you actually used successfully)
cat > autocycler_resume.sh << 'EOF'
#!/usr/bin/env bash
set -e

# Usage: ./autocycler_resume.sh <read_fastq> <threads> [read_type]

reads=$1
threads=$2
read_type=${3:-ont_r10}

echo "=== Autocycler RESUME: Using existing assemblies/ folder ==="
echo "Raven assemblies found: $(ls assemblies/raven*.fasta 2>/dev/null || echo 'none')"

if [[ ! -d "assemblies" || ! -f "assemblies/raven_01.fasta" ]]; then
    echo "ERROR: Need assemblies/raven_01.fasta from previous Raven run" >&2
    exit 1
fi

echo "Step 3: compress..."
autocycler compress -i assemblies -a autocycler_out 2>> autocycler.stderr

echo "Step 4: cluster..."
autocycler cluster -a autocycler_out 2>> autocycler.stderr

echo "Steps 5-6: trim & resolve clusters..."
for c in autocycler_out/clustering/qc_pass/cluster_*; do
    if [[ -d "$c" ]]; then
        echo "  Processing $c..."
        autocycler trim -c "$c" 2>> autocycler.stderr
        autocycler resolve -c "$c" 2>> autocycler.stderr
    fi
done

echo "Step 7: combine final assembly..."
autocycler combine -a autocycler_out -i autocycler_out/clustering/qc_pass/cluster_*/5_final.gfa 2>> autocycler.stderr

echo "=== COMPLETE! Final assembly: autocycler_out/6_combined/ ==="
ls -lh autocycler_out/6_combined/ || true
tail -n 20 autocycler.stderr || true
EOF

chmod +x autocycler_resume.sh

# 2.4 Run Autocycler resume on filtered ONT reads
# Precondition: assemblies/raven_01.fasta exists from your Raven run
autocycler_resume.sh reads_qc/ont.fastq 4 ont_r10

# 2.5 Copy main Autocycler consensus assembly for downstream polishing
cp autocycler_out/consensus_assembly.fasta autocycler_assembly.fasta
ls -lh autocycler_assembly.fasta

