#!/bin/bash
#SBATCH --job-name=abricate_resistance
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=4:00:00
#SBATCH --output=logs/abricate_resistance_%j.out

source ~/.bashrc
conda activate abricate_env

# Navigate to the correct directory
cd /etc/ace-data/home/golweny/saureus/fastq_files/trimmed_fastq/high_confidence_fastqs/spades_assemblies/good_assemblies

# Create output directory if it doesn't exist
mkdir -p abricate_results

echo "=== Running Abricate for Resistance Genes ==="
abricate --db ncbi prokka_results/*_prokka/*.gbk > abricate_results/resistance_all.tsv
abricate --summary abricate_results/resistance_all.tsv > abricate_results/resistance_summary.tsv

echo "✓ Resistance profiling complete"
