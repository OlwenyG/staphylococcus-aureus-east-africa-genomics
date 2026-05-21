#!/bin/bash
#SBATCH --job-name=abricate_virulence
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=4:00:00
#SBATCH --output=logs/abricate_virulence_%j.out

source ~/.bashrc
conda activate abricate_env

echo "=== Running Abricate for Virulence Factors ==="
echo "Working directory: $(pwd)"

# Create specific output directory
mkdir -p abricate_virulence

abricate --db vfdb prokka_results/*_prokka/*.gbk > abricate_virulence/virulence_all.tsv
abricate --summary abricate_virulence/virulence_all.tsv > abricate_virulence/virulence_summary.tsv

echo "✓ Virulence profiling complete"
echo "Results saved to abricate_virulence/"
