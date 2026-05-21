#!/bin/bash
#SBATCH --job-name=spa_typing
#SBATCH --output=logs/spa_typing_%j.out
#SBATCH --error=logs/spa_typing_%j.err
#SBATCH --mem=30G
#SBATCH --cpus-per-task=16
#SBATCH --partition=normal

# ===========================================
# MINIMAL SPA TYPING SCRIPT
# Just runs spaTyper and saves output
# ===========================================

source ~/.bashrc
conda activate bacterial-genomics-tutorial

# Create output directory
mkdir -p spa_typing_results
mkdir -p logs

echo "Starting spa typing at: $(date)"

# Run spaTyper on all files
spaTyper \
    --glob "*contigs.fasta" \
    --folder "spa_typing_results/ridom_downloads" \
    --output "spa_typing_results/all_samples_spa_results.txt"

echo "Completed at: $(date)"
echo "Results in: spa_typing_results/all_samples_spa_results.txt"
