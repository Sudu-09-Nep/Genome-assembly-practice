x#!/usr/bin/env bash

# RESUME Autocycler script - skips subsampling & assembly (Raven already done)
# Usage: ./autocycler_resume.sh <read_fastq> <threads> <read_type>
# Save as autocycler_resume.sh in your terminal/ directory

set -e

# Get arguments
reads=$1
threads=$2
read_type=${3:-ont_r10}

echo "=== Autocycler RESUME: Using existing assemblies/ folder ==="
echo "Raven assemblies found: $(ls assemblies/raven*.fasta 2>/dev/null || echo 'none')"

# Validate inputs
if [[ ! -d "assemblies" || ! -f "assemblies/raven_01.fasta" ]]; then
    echo "ERROR: Need assemblies/raven_01.fasta from previous Raven run" >&2
    exit 1
fi

# Step 3: compress the input assemblies into a unitig graph
echo "Step 3: compress..."
autocycler compress -i assemblies -a autocycler_out 2>> autocycler.stderr

# Step 4: cluster the input contigs into putative genomic sequences
echo "Step 4: cluster..."
autocycler cluster -a autocycler_out 2>> autocycler.stderr

# Steps 5 and 6: trim and resolve each QC-pass cluster
echo "Steps 5-6: trim & resolve clusters..."
for c in autocycler_out/clustering/qc_pass/cluster_*; do
    if [[ -d "$c" ]]; then
        echo "  Processing $c..."
        autocycler trim -c "$c" 2>> autocycler.stderr
        autocycler resolve -c "$c" 2>> autocycler.stderr
    fi
done

# Step 7: combine resolved clusters into a final assembly
echo "Step 7: combine final assembly..."
autocycler combine -a autocycler_out -i autocycler_out/clustering/qc_pass/cluster_*/5_final.gfa 2>> autocycler.stderr

echo "=== COMPLETE! Final assembly: autocycler_out/6_combined/ ==="
ls -lh autocycler_out/6_combined/
tail -n 20 autocycler.stderr
