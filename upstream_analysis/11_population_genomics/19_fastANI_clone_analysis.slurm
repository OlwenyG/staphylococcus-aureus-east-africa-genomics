#!/bin/bash
#SBATCH --job-name=fastANI_313
#SBATCH --output=logs/fastANI_%j.out
#SBATCH --error=logs/fastANI_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30
#SBATCH --mem=70G
#SBATCH --time=24:00:00

set -euo pipefail

echo "======================================="
echo "Starting fastANI clone analysis"
echo "Date: $(date)"
echo "Host: $(hostname)"
echo "======================================="

cd /etc/ace-data/home/golweny/saureus/fastq_files/trimmed_fastq/high_confidence_fastqs/spades_assemblies/good_assemblies

mkdir -p clone_analysis/fastani
mkdir -p logs

FASTANI="$HOME/.conda/envs/fastani_env/bin/fastANI"

echo "Using fastANI:"
$FASTANI --version

echo "Generating assembly list..."
ls *_contigs.fasta > clone_analysis/fastani/assemblies.list

echo "Number of assemblies:"
wc -l clone_analysis/fastani/assemblies.list

echo "Running all-vs-all fastANI..."

$FASTANI \
  --ql clone_analysis/fastani/assemblies.list \
  --rl clone_analysis/fastani/assemblies.list \
  -o clone_analysis/fastani/fastani_all_vs_all.tsv \
  -t ${SLURM_CPUS_PER_TASK}

echo "fastANI completed successfully"

awk '$1 != $2 && $3 >= 99.99' \
clone_analysis/fastani/fastani_all_vs_all.tsv \
> clone_analysis/fastani/putative_clones_99.99ANI.tsv

awk '$1 != $2 && $3 >= 99.95' \
clone_analysis/fastani/fastani_all_vs_all.tsv \
> clone_analysis/fastani/putative_clones_99.95ANI.tsv

echo "Clone pair counts:"
wc -l clone_analysis/fastani/putative_clones_99.99ANI.tsv
wc -l clone_analysis/fastani/putative_clones_99.95ANI.tsv

echo "Finished fastANI analysis"
echo "Date: $(date)"
