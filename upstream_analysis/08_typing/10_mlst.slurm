#!/bin/bash
#SBATCH --job-name=mlst_typing
#SBATCH --cpus-per-task=30
#SBATCH --mem=64G
#SBATCH --time=2:00:00
#SBATCH --output=logs/mlst_%j.out
#SBATCH --chdir=/etc/ace-data/home/golweny/saureus/fastq_files/trimmed_fastq/high_confidence_fastqs/spades_assemblies/good_assemblies

source ~/.bashrc
conda activate mlst_env

echo "=== Running MLST Typing ==="
mkdir -p mlst_results

# MLST on Prokka FSA files
mlst prokka_results/*_prokka/*.fsa > mlst_results/mlst_all.tsv

echo "✓ MLST typing complete"
echo "Sequence Types found:"
cut -f2,3 mlst_results/mlst_all.tsv | sort | uniq -c | sort -nr
