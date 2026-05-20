#!/bin/bash
#SBATCH --job-name=quast_313
#SBATCH --cpus-per-task=30
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=logs/quast_313_%j.out
#SBATCH --error=logs/quast_313_%j.err

source ~/.bashrc
conda activate bacterial-genomics-tutorial


echo "Running QUAST on 313 S. aureus assemblies..."
quast.py *.fasta -o quast_results_313 --threads 30 --space-efficient --gene-finding

echo "QUAST completed successfully!"
