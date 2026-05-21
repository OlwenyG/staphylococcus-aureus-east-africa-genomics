#!/bin/bash
#SBATCH --job-name=isescan
#SBATCH --output=logs/isescan_%j.out
#SBATCH --error=logs/isescan_%j.err
#SBATCH --ntasks=1
#SBATCH --mem=50G
#SBATCH --cpus-per-task=30


source ~/.bashrc
conda activate isescan_env
export LD_LIBRARY_PATH=~/.isescan/ISEScan:$LD_LIBRARY_PATH

cd /etc/ace-data/home/golweny/saureus/fastq_files/trimmed_fastq/high_confidence_fastqs/spades_assemblies/good_assemblies

# Create results directory
ISESCAN_RESULTS="isescan_results"
mkdir -p "$ISESCAN_RESULTS"
mkdir -p logs

echo "=== Starting ISEScan Analysis ==="
echo "Start time: $(date)"

# Count total files
total_files=$(ls *_contigs.fasta 2>/dev/null | wc -l)
echo "Found $total_files contig files to process"

current=0
success_count=0
fail_count=0

# Process each contig file
for CONTIG_FILE in *_contigs.fasta; do
    current=$((current + 1))
    SAMPLE_NAME=$(basename "$CONTIG_FILE" _contigs.fasta)
    
    echo "-------------------------------------------------------------------"
    echo "[$current/$total_files] Processing: $SAMPLE_NAME"
    
    # Run ISEScan
    isescan.py --seqfile "$CONTIG_FILE" --output "$ISESCAN_RESULTS/${SAMPLE_NAME}"
    
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "✓ SUCCESS: $SAMPLE_NAME"
        success_count=$((success_count + 1))
        
        # Check for insertion sequences and count them
        if [ -f "$ISESCAN_RESULTS/${SAMPLE_NAME}.is.fna" ]; then
            is_count=$(grep -c ">" "$ISESCAN_RESULTS/${SAMPLE_NAME}.is.fna" 2>/dev/null || echo 0)
            echo "  Found $is_count insertion sequences"
        else
            echo "  No insertion sequences found"
        fi
    else
        echo "✗ FAILED: $SAMPLE_NAME (exit code: $exit_code)"
        fail_count=$((fail_count + 1))
    fi
done

echo "==================================================================="
echo "ISEScan ANALYSIS COMPLETED"
echo "Successfully processed: $success_count/$total_files samples"
echo "Failed: $fail_count/$total_files samples"
echo "End time: $(date)"
echo "Results saved to: $ISESCAN_RESULTS/"
echo "==================================================================="

# Create summary file
SUMMARY_FILE="$ISESCAN_RESULTS/isescan_analysis_summary.txt"
{
    echo "ISEScan Analysis Summary"
    echo "========================"
    echo "Date: $(date)"
    echo "Total samples: $total_files"
    echo "Successfully processed: $success_count"
    echo "Failed: $fail_count"
    echo ""
    echo "Output directory: $ISESCAN_RESULTS"
} > "$SUMMARY_FILE"

echo "Summary saved to: $SUMMARY_FILE"
