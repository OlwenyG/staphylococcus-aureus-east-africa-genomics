#!/bin/bash
#SBATCH --job-name=abricate_plasmid
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=4:00:00
#SBATCH --output=logs/abricate_plasmid_%j.out

source ~/.bashrc
conda activate abricate_env

echo "=== Running Abricate for Plasmid Replicons ==="
echo "Working directory: $(pwd)"

# Create specific output directory
mkdir -p abricate_plasmid

# Check available databases
echo "Available Abricate databases:"
abricate --list

# Run plasmid analysis with CORRECT database name
abricate --db plasmidfinder prokka_results/*_prokka/*.gbk > abricate_plasmid/plasmid_all.tsv
abricate --summary abricate_plasmid/plasmid_all.tsv > abricate_plasmid/plasmid_summary.tsv

echo "✓ Plasmid replicon profiling complete"
echo "Results saved to abricate_plasmid/"
