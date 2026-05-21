#!/bin/bash
#SBATCH --job-name=phigaro_all
#SBATCH --output=logs/phigaro_all_%j.out
#SBATCH --error=logs/phigaro_all_%j.err
#SBATCH --ntasks=1
#SBATCH --mem=50G
#SBATCH --cpus-per-task=30

source ~/.bashrc
conda activate phage_analysis_clean

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PHIGARO_RESULTS="phigaro_results_${TIMESTAMP}"
mkdir -p "$PHIGARO_RESULTS" logs

echo "sample,status,phage_count,time_sec,contigs_total,contigs_ge_20kb" > "${PHIGARO_RESULTS}/results.csv"

total_files=$(ls *_contigs.fasta 2>/dev/null | wc -l)
current=0

for CONTIG_FILE in *_contigs.fasta; do
    current=$((current + 1))
    SAMPLE_NAME=$(basename "$CONTIG_FILE" _contigs.fasta)
    SAMPLE_OUTPUT="$PHIGARO_RESULTS/${SAMPLE_NAME}"
    mkdir -p "$SAMPLE_OUTPUT"
    
    echo "[$current/$total_files] Processing: $SAMPLE_NAME"
    
    # Get stats
    total_contigs=$(grep -c '>' "$CONTIG_FILE")
    contigs_ge_20kb=$(bioawk -c fastx 'length($seq) >= 20000 {print $name}' "$CONTIG_FILE" | wc -l)
    
    start_time=$(date +%s)
    
    # USE --delete-shorts FLAG - This automatically removes short sequences without prompting
    phigaro -f "$CONTIG_FILE" \
            -o "$SAMPLE_OUTPUT" \
            -e tsv gff html \
            --save-fasta \
            --delete-shorts \
            -t 30 > "${SAMPLE_OUTPUT}/stdout" 2> "${SAMPLE_OUTPUT}/stderr"
    
    exit_code=$?
    duration=$(( $(date +%s) - start_time ))
    
    if [ $exit_code -eq 0 ]; then
        TSV_FILE=$(find "$SAMPLE_OUTPUT" -name "*.tsv" | head -1)
        if [ -f "$TSV_FILE" ]; then
            phage_count=$(tail -n +2 "$TSV_FILE" | wc -l 2>/dev/null || echo 0)
            echo "SUCCESS: $SAMPLE_NAME - $phage_count phages (${duration}s)"
            echo "${SAMPLE_NAME},SUCCESS,${phage_count},${duration},${total_contigs},${contigs_ge_20kb}" >> "${PHIGARO_RESULTS}/results.csv"
        else
            echo "SUCCESS: $SAMPLE_NAME - No phages (${duration}s)"
            echo "${SAMPLE_NAME},SUCCESS,0,${duration},${total_contigs},${contigs_ge_20kb}" >> "${PHIGARO_RESULTS}/results.csv"
        fi
    else
        echo "FAILED: $SAMPLE_NAME (${duration}s)"
        echo "${SAMPLE_NAME},FAILED,0,${duration},${total_contigs},${contigs_ge_20kb}" >> "${PHIGARO_RESULTS}/results.csv"
    fi
    
    sleep 1
done

echo "Analysis complete! Results: $PHIGARO_RESULTS"
