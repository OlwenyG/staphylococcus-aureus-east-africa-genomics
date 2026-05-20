#!/bin/bash
#SBATCH --job-name=prokka_313
#SBATCH --array=1-313%5
#SBATCH --cpus-per-task=30
#SBATCH --mem=50G
#SBATCH --output=logs/prokka_%A_%a.out
#SBATCH --error=logs/prokka_%A_%a.err

source ~/.bashrc
conda activate prokka_env


# Create output directory
mkdir -p prokka_results

# Get sample for this array task
SAMPLES=($(ls *_contigs.fasta | sed 's/_contigs.fasta//' | sort))
SAMPLE=${SAMPLES[$SLURM_ARRAY_TASK_ID-1]}

echo "=== Prokka Annotation: $SAMPLE ==="
echo "Started: $(date)"

# Skip if already done
if [[ -d "prokka_results/${SAMPLE}_prokka" ]]; then
    echo "✓ Already annotated: $SAMPLE"
    exit 0
fi

# Run Prokka (same parameters as successful test)
prokka --outdir prokka_results/${SAMPLE}_prokka \
       --prefix $SAMPLE \
       --genus Staphylococcus \
       --species aureus \
       --strain $SAMPLE \
       --cpus 30 \
       --compliant \
       --centre X \
       ${SAMPLE}_contigs.fasta

# Check success
if [[ $? -eq 0 ]] && [[ -f "prokka_results/${SAMPLE}_prokka/${SAMPLE}.gff" ]]; then
    echo "✓ SUCCESS: $SAMPLE"
else
    echo "✗ FAILED: $SAMPLE"
    exit 1
fi

echo "Finished: $(date)"
