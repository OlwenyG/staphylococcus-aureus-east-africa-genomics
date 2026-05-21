#!/bin/bash
#SBATCH --job-name=sccmec
#SBATCH --output=logs/sccmec_%j.out
#SBATCH --error=logs/sccmec_%j.err
#SBATCH --ntasks=1
#SBATCH --mem=50G
#SBATCH --cpus-per-task=30
#SBATCH --time=12:00:00

source ~/.bashrc
conda activate sccmec

cd /etc/ace-data/home/golweny/saureus/fastq_files/trimmed_fastq/high_confidence_fastqs/spades_assemblies/good_assemblies

# Create results directory
SCCMEC_RESULTS="sccmec_results"
mkdir -p "$SCCMEC_RESULTS"
mkdir -p logs

echo "=== Starting SCCmec Analysis ==="
echo "Start time: $(date)"

# Count total files
total_files=$(ls *_contigs.fasta 2>/dev/null | wc -l)
echo "Found $total_files contig files to process"

current=0
success_count=0

# Process each contig file
for CONTIG_FILE in *_contigs.fasta; do
    current=$((current + 1))
    SAMPLE_NAME=$(basename "$CONTIG_FILE" _contigs.fasta)
    SAMPLE_OUTPUT="$SCCMEC_RESULTS/${SAMPLE_NAME}"
    mkdir -p "$SAMPLE_OUTPUT"
    
    echo "[$current/$total_files] Processing: $SAMPLE_NAME"
    
    # Run sccmec with default parameters
    sccmec --input "$CONTIG_FILE" --outdir "$SAMPLE_OUTPUT" --prefix "$SAMPLE_NAME"
    
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "✓ SUCCESS: $SAMPLE_NAME"
        success_count=$((success_count + 1))
    else
        echo "✗ FAILED: $SAMPLE_NAME (exit code: $exit_code)"
    fi
done

echo "==================================================================="
echo "SCCMEC ANALYSIS COMPLETED"
echo "Successfully processed: $success_count/$total_files samples"
echo "End time: $(date)"
echo "Results saved to: $SCCMEC_RESULTS/"
echo "==================================================================="

# Create comprehensive final reports
echo "=== Generating Final Reports ==="

# 1. Combined master TSV with all data
COMBINED_TSV="$SCCMEC_RESULTS/ALL_SAMPLES_SCCmec_combined.tsv"
echo "Creating combined TSV: $COMBINED_TSV"

# Initialize with header from first file
first_tsv=$(find "$SCCMEC_RESULTS" -name "*.tsv" | head -1)
if [ -n "$first_tsv" ]; then
    head -1 "$first_tsv" > "$COMBINED_TSV"
    
    # Append all data (skip headers)
    for tsv_file in "$SCCMEC_RESULTS"/*/*.tsv; do
        if [ -f "$tsv_file" ]; then
            tail -n +2 "$tsv_file" >> "$COMBINED_TSV"
        fi
    done
fi

# 2. Summary statistics report
SUMMARY_REPORT="$SCCMEC_RESULTS/SCCmec_Summary_Report.txt"

{
    echo "SCCmec TYPING SUMMARY REPORT"
    echo "============================"
    echo "Analysis Date: $(date)"
    echo "Total Samples Processed: $success_count"
    echo ""
    
    echo "SCCmec TYPE DISTRIBUTION:"
    echo "-------------------------"
    if [ -f "$COMBINED_TSV" ]; then
        tail -n +2 "$COMBINED_TSV" | cut -f2 | sort | uniq -c | sort -nr | while read count type; do
            if [ -z "$type" ] || [ "$type" = "-" ]; then
                echo "  $count  No SCCmec detected"
            else
                echo "  $count  Type $type"
            fi
        done
    fi
    
    echo ""
    echo "mecA GENE STATUS:"
    echo "-----------------"
    if [ -f "$COMBINED_TSV" ]; then
        tail -n +2 "$COMBINED_TSV" | cut -f4 | sort | uniq -c | while read count status; do
            case "$status" in
                "+") echo "  $count  mecA positive (MRSA)" ;;
                "-") echo "  $count  mecA negative (MSSA)" ;;
                *) echo "  $count  Unknown mecA status: $status" ;;
            esac
        done
    fi
    
    echo ""
    echo "SUBTYPE DISTRIBUTION:"
    echo "---------------------"
    if [ -f "$COMBINED_TSV" ]; then
        tail -n +2 "$COMBINED_TSV" | cut -f3 | sort | uniq -c | sort -nr | while read count subtype; do
            if [ -z "$subtype" ] || [ "$subtype" = "-" ]; then
                echo "  $count  No subtype"
            else
                echo "  $count  Subtype $subtype"
            fi
        done
    fi
    
    echo ""
    echo "SAMPLES BY SCCmec TYPE:"
    echo "-----------------------"
    if [ -f "$COMBINED_TSV" ]; then
        # Group samples by type
        tail -n +2 "$COMBINED_TSV" | awk -F'\t' '
        {
            type = ($2 == "" || $2 == "-") ? "None" : $2;
            mecA = ($4 == "+") ? "MRSA" : "MSSA";
            samples[type][mecA] = samples[type][mecA] " " $1
        }
        END {
            for (type in samples) {
                print "Type " type ":"
                for (mecA in samples[type]) {
                    count = split(samples[type][mecA], arr, " ") - 1;
                    print "  " mecA " (" count " samples):" samples[type][mecA]
                }
                print ""
            }
        }' >> "$SUMMARY_REPORT"
    fi

} > "$SUMMARY_REPORT"

# 3. Create a simplified CSV for easy analysis
SIMPLIFIED_CSV="$SCCMEC_RESULTS/SCCmec_Simplified_Summary.csv"
{
    echo "Sample,SCCmec_Type,Subtype,mecA_Status,MRSA_Status,Target_Genes"
    if [ -f "$COMBINED_TSV" ]; then
        tail -n +2 "$COMBINED_TSV" | awk -F'\t' '{
            type = ($2 == "" || $2 == "-") ? "None" : $2;
            subtype = ($3 == "" || $3 == "-") ? "None" : $3;
            mecA_status = ($4 == "+") ? "Positive" : "Negative";
            MRSA_status = ($4 == "+") ? "MRSA" : "MSSA";
            # Clean targets for CSV (remove commas or replace with semicolons)
            targets = $5;
            gsub(/,/, ";", targets);
            print $1 "," type "," subtype "," mecA_status "," MRSA_status "," targets
        }'
    fi
} > "$SIMPLIFIED_CSV"

echo ""
echo "=== FINAL REPORTS GENERATED ==="
echo "1. Combined TSV: $COMBINED_TSV"
echo "2. Summary Report: $SUMMARY_REPORT" 
echo "3. Simplified CSV: $SIMPLIFIED_CSV"
echo ""
echo "Use these files for your analysis:"
echo "- $SIMPLIFIED_CSV - For Excel/Python/R analysis"
echo "- $SUMMARY_REPORT - For quick overview"
echo "- $COMBINED_TSV - For all detailed data"
