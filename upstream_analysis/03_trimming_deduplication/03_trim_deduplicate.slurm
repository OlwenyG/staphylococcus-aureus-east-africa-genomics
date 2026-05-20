#!/bin/bash
#SBATCH --job-name=trimming_fixed
#SBATCH --output=trimming_fixed_%A_%a.out
#SBATCH --error=trimming_fixed_%A_%a.err
#SBATCH --cpus-per-task=30
#SBATCH --mem=50G
#SBATCH --time=4:00:00
#SBATCH --partition=normal
#SBATCH --array=1-21%10

source ~/.bashrc
conda activate bacterial-genomics-tutorial

# Set variables
BATCH_SIZE=50
ADAPTER_FILE="/opt/anaconda3/envs/ACE_training_2025-09/share/trimmomatic-0.40-0/adapters/TruSeq3-PE-2.fa"

# Get all R1 files
SAMPLES=($(ls *_1.fastq.gz | sort))

# Calculate batch range
START_IDX=$(( ($SLURM_ARRAY_TASK_ID - 1) * $BATCH_SIZE ))
END_IDX=$(( $START_IDX + $BATCH_SIZE - 1 ))

echo "=== Starting Batch $SLURM_ARRAY_TASK_ID ==="
echo "Processing samples $START_IDX to $END_IDX"
echo "Total samples in batch: $((END_IDX - START_IDX + 1))"

# Create output directory
mkdir -p trimmed_fastq

# Counter for this batch
processed=0

# Process samples in this batch
for ((i=$START_IDX; i<=$END_IDX; i++)); do
    if [ $i -lt ${#SAMPLES[@]} ]; then
        r1=${SAMPLES[$i]}
        r2=${r1/_1.fastq.gz/_2.fastq.gz}
        base=${r1%_1.fastq.gz}
        
        echo "[$((i-START_IDX+1))] Processing: $base"
        
        # Check if both files exist
        if [ ! -f "$r2" ]; then
            echo "  WARNING: Reverse read $r2 not found, skipping..."
            continue
        fi
        
        # Step 1: Trimming with Trimmomatic
        echo "  Running Trimmomatic..."
        trimmomatic PE -phred33 -threads 2 \
            $r1 $r2 \
            trimmed_fastq/${base}_R1_paired.fq.gz trimmed_fastq/${base}_R1_unpaired.fq.gz \
            trimmed_fastq/${base}_R2_paired.fq.gz trimmed_fastq/${base}_R2_unpaired.fq.gz \
            ILLUMINACLIP:${ADAPTER_FILE}:2:30:10:2:keepBothReads \
            LEADING:15 \
            TRAILING:15 \
            SLIDINGWINDOW:4:25 \
            MINLEN:85 \
            AVGQUAL:25
        
        # Step 2: Deduplication - FIXED version (no dupdist parameter)
        echo "  Running deduplication..."
        clumpify.sh in=trimmed_fastq/${base}_R1_paired.fq.gz in2=trimmed_fastq/${base}_R2_paired.fq.gz \
            out=trimmed_fastq/${base}_R1_clean.fq.gz out2=trimmed_fastq/${base}_R2_clean.fq.gz \
            dedupe=t
        
        # Clean up intermediate files
        rm trimmed_fastq/${base}_R1_paired.fq.gz trimmed_fastq/${base}_R2_paired.fq.gz
        rm trimmed_fastq/${base}_R1_unpaired.fq.gz trimmed_fastq/${base}_R2_unpaired.fq.gz
        
        processed=$((processed + 1))
        echo "  ✓ Completed: $base"
    fi
done

echo "=== Batch $SLURM_ARRAY_TASK_ID Finished ==="
echo "Successfully processed $processed samples"
