#!/bin/bash
#SBATCH --job-name=sra_array
#SBATCH --output=logs/sra_array_%A_%a.out
#SBATCH --error=logs/sra_array_%A_%a.err
#SBATCH --cpus-per-task=32
#SBATCH --mem=50G
#SBATCH --array=1-502%5   # 502 accessions, max 5 concurrent

# =============================
# Environment setup
# =============================
source ~/.bashrc
conda activate bacterial-genomics-tutorial

# Required tools check
which prefetch fasterq-dump pigz esearch efetch || { echo "ERROR: Tools missing"; exit 1; }

# =============================
# Directories
# =============================
mkdir -p sra_files fastq_files logs scratch

# =============================
# Get accession for this array task
# =============================
accession=$(sed -n "${SLURM_ARRAY_TASK_ID}p" logs/all_accessions.txt)
if [ -z "$accession" ]; then
    echo "ERROR: No accession found for task ${SLURM_ARRAY_TASK_ID}" >&2
    exit 1
fi

# Use project-local scratch instead of /scratch
scratch_dir=$PWD/scratch/${SLURM_JOB_ID}_${accession}
mkdir -p "$scratch_dir"

echo "[$(date)] Starting task $SLURM_ARRAY_TASK_ID for accession $accession"

# =============================
# Step 1: Prefetch SRA
# =============================
prefetch --max-size 100G --progress -O sra_files $accession \
    >> logs/${accession}_prefetch.log 2>&1

if [ ! -f "sra_files/${accession}.sra" ]; then
    echo "[$(date)] ERROR: Prefetch failed for $accession" >> logs/errors.log
    rm -rf "$scratch_dir"
    exit 1
fi

# =============================
# Step 2: Convert to FASTQ
# =============================
fasterq-dump sra_files/${accession}.sra \
    --outdir fastq_files \
    --temp "$scratch_dir" \
    --threads 4 \
    --split-files \
    --skip-technical \
    --progress \
    >> logs/${accession}_fasterq.log 2>&1

if [ $? -ne 0 ]; then
    echo "[$(date)] ERROR: fasterq-dump failed for $accession" >> logs/errors.log
    rm -rf "$scratch_dir"
    exit 1
fi

# =============================
# Step 3: Compress FASTQ files
# =============================
if ls fastq_files/${accession}_*.fastq 1> /dev/null 2>&1; then
    pigz -p 4 fastq_files/${accession}_*.fastq
    echo "[$(date)] Compressed FASTQs for $accession"
else
    echo "[$(date)] WARNING: No FASTQs for $accession" >> logs/warnings.log
fi

# =============================
# Cleanup
# =============================
rm -rf "$scratch_dir"
rm -f sra_files/${accession}.sra   # comment this line if you want to keep the SRA files

echo "[$(date)] Finished accession $accession"
