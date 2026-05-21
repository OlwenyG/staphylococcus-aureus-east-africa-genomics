#!/bin/bash
#SBATCH --job-name=roary_pangenome
#SBATCH --cpus-per-task=30
#SBATCH --mem=64G
#SBATCH --output=logs/roary_%j.out
#SBATCH --chdir=/etc/ace-data/home/golweny/saureus/fastq_files/trimmed_fastq/high_confidence_fastqs/spades_assemblies/good_assemblies

source ~/.bashrc
conda activate roary_env

echo "=== Running Roary Pangenome Analysis ==="
mkdir -p roary_results

# Run Roary on all GFF files
roary -f roary_results -e -n -v -p 30 prokka_results/*_prokka/*.gff

echo "✓ Roary pangenome analysis complete"
echo "=== Pangenome Statistics ==="
cat roary_results/summary_statistics.txt

