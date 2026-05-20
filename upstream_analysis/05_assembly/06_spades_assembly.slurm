#!/bin/bash
#SBATCH --job-name=spades_array
#SBATCH --array=1-431%5
#SBATCH --cpus-per-task=30
#SBATCH --mem=80G
#SBATCH --output=logs/spades_%A_%a.out
#SBATCH --error=logs/spades_%A_%a.err

source ~/.bashrc
conda activate bacterial-genomics-tutorial

mkdir -p spades_assemblies logs

# Get sample for this array task
SAMPLES=($(ls *_R1_clean.fq.gz | sed 's/_R1_clean.fq.gz//' | sort))
SAMPLE=${SAMPLES[$SLURM_ARRAY_TASK_ID-1]}

R1="${SAMPLE}_R1_clean.fq.gz"
R2="${SAMPLE}_R2_clean.fq.gz"
OUTPUT_DIR="spades_assemblies/${SAMPLE}_SPADES_OUT"

echo "=== SPAdes Assembly ==="
echo "Task: $SLURM_ARRAY_TASK_ID - $SAMPLE"
echo "Started: $(date)"

# Skip if already done
if [[ -f "spades_assemblies/${SAMPLE}_contigs.fasta" ]]; then
    echo "✓ Already completed: $SAMPLE"
    exit 0
fi

# Clean output directory if it exists from previous failed runs
if [[ -d "$OUTPUT_DIR" ]]; then
    rm -rf "$OUTPUT_DIR"
fi

# Run SPAdes with --isolate (recommended for bacterial isolates)
# Remove --careful flag as it's incompatible with --isolate
spades.py \
    --isolate \
    -1 "$R1" \
    -2 "$R2" \
    -o "$OUTPUT_DIR" \
    --threads 30 \
    --memory 80 \
    --only-assembler

# Check success
if [[ -f "$OUTPUT_DIR/contigs.fasta" ]]; then
    cp "$OUTPUT_DIR/contigs.fasta" "spades_assemblies/${SAMPLE}_contigs.fasta"
    echo "✓ SUCCESS: $SAMPLE"
else
    echo "✗ FAILED: $SAMPLE"
    exit 1
fi

echo "Finished: $(date)"
