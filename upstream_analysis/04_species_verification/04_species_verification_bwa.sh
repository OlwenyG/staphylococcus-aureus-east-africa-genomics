#!/bin/bash
#SBATCH --job-name=staph_verify_fixed
#SBATCH --output=staph_verify_fixed_%j.out
#SBATCH --error=staph_verify_fixed_%j.err
#SBATCH --cpus-per-task=32
#SBATCH --mem=80G
#SBATCH --time=8:00:00
#SBATCH --partition=normal

source ~/.bashrc
conda activate bacterial-genomics-tutorial

echo "Starting S. aureus species verification (fixed version)..."

# Check if reference exists
if [ ! -f "../../references/saureus_ref.fasta" ]; then
    echo "ERROR: Reference genome not found"
    exit 1
fi

echo "✓ Reference genome found"

# Create fresh output directories
rm -rf mapping_results_fixed
mkdir -p mapping_results_fixed

# Get list of samples
ls *_R1_clean.fq.gz | sed 's/_R1_clean.fq.gz//' > sample_list_fixed.txt
TOTAL_SAMPLES=$(wc -l < sample_list_fixed.txt)
echo "Found $TOTAL_SAMPLES samples for verification"

# Function to process one sample (using bc for floating point math)
process_sample_fixed() {
    local sample=$1
    
    echo "[$(date '+%H:%M:%S')] Processing: $sample"
    
    # Map reads to S. aureus reference
    bwa mem -t 2 ../../references/saureus_ref.fasta \
        ${sample}_R1_clean.fq.gz \
        ${sample}_R2_clean.fq.gz 2> mapping_results_fixed/${sample}_bwa.log | \
    samtools view -b - > mapping_results_fixed/${sample}.bam 2> mapping_results_fixed/${sample}_samtools.log
    
    # Check if mapping was successful
    if [ ! -f "mapping_results_fixed/${sample}.bam" ]; then
        echo "$sample,0,0,0,0,0,MAPPING_FAILED,FAILED"
        return 1
    fi
    
    # Get mapping statistics using Python for reliable math
    python3 - <<END
import subprocess
import sys

sample = "$sample"

# Get flagstat output
result = subprocess.run(['samtools', 'flagstat', f'mapping_results_fixed/{sample}.bam'], 
                       capture_output=True, text=True)
    
if result.returncode == 0:
    lines = result.stdout.strip().split('\n')
    total_reads = int(lines[0].split()[0])
    mapped_reads = int(lines[4].split()[0])
    properly_paired = int(lines[8].split()[0])
    
    if total_reads > 0:
        mapping_pct = (mapped_reads / total_reads) * 100
        proper_pair_pct = (properly_paired / total_reads) * 100
        
        # Classification
        if mapping_pct > 85:
            status = "HIGH_CONFIDENCE_SA"
        elif mapping_pct > 60:
            status = "LIKELY_SA"
        elif mapping_pct > 30:
            status = "POSSIBLE_SA"
        else:
            status = "UNLIKELY_SA"
            
        # Quality
        if proper_pair_pct > 70:
            quality = "GOOD"
        elif proper_pair_pct > 40:
            quality = "MEDIUM"
        else:
            quality = "POOR"
            
        print(f"{sample},{total_reads},{mapped_reads},{mapping_pct:.2f},{properly_paired},{proper_pair_pct:.2f},{status},{quality}")
    else:
        print(f"{sample},0,0,0,0,0,NO_READS,FAILED")
else:
    print(f"{sample},0,0,0,0,0,FLAGSTAT_FAILED,FAILED")
END
    
    # Clean up BAM file
    rm mapping_results_fixed/${sample}.bam 2>/dev/null
}

export -f process_sample_fixed

# Create results file with header
echo "sample,total_reads,mapped_reads,mapping_percentage,properly_paired,proper_pair_percentage,classification,quality" > staph_verification_results_fixed.csv

# Process samples in parallel
echo "Starting parallel processing of $TOTAL_SAMPLES samples..."
cat sample_list_fixed.txt | parallel -j 8 --joblog mapping_results_fixed/parallel.log process_sample_fixed {} >> staph_verification_results_fixed.csv

echo "Species verification complete!"

# Generate summary report
echo -e "\n=== VERIFICATION SUMMARY ==="
python3 - <<END
import pandas as pd

try:
    df = pd.read_csv('staph_verification_results_fixed.csv')
    total_samples = len(df)
    
    high_conf = len(df[df['classification'] == 'HIGH_CONFIDENCE_SA'])
    likely = len(df[df['classification'] == 'LIKELY_SA'])
    possible = len(df[df['classification'] == 'POSSIBLE_SA'])
    unlikely = len(df[df['classification'] == 'UNLIKELY_SA'])
    failed = len(df[df['classification'].str.contains('FAILED|NO_READS')])
    
    print(f"Total samples processed: {total_samples}")
    print(f"High confidence S. aureus: {high_conf} ({high_conf/total_samples*100:.1f}%)")
    print(f"Likely S. aureus: {likely} ({likely/total_samples*100:.1f}%)")
    print(f"Possible S. aureus: {possible} ({possible/total_samples*100:.1f}%)")
    print(f"Unlikely S. aureus: {unlikely} ({unlikely/total_samples*100:.1f}%)")
    print(f"Failed: {failed} ({failed/total_samples*100:.1f}%)")
    
    # Create filtered lists
    high_conf_samples = df[df['classification'] == 'HIGH_CONFIDENCE_SA']['sample'].tolist()
    confident_samples = df[df['classification'].isin(['HIGH_CONFIDENCE_SA', 'LIKELY_SA'])]['sample'].tolist()
    
    with open('high_confidence_sa_fixed.txt', 'w') as f:
        f.write('\n'.join(high_conf_samples))
    
    with open('confident_sa_fixed.txt', 'w') as f:
        f.write('\n'.join(confident_samples))
    
    print(f"\nFiltered sample lists created:")
    print(f"High confidence only: high_confidence_sa_fixed.txt ({len(high_conf_samples)} samples)")
    print(f"All confident S. aureus: confident_sa_fixed.txt ({len(confident_samples)} samples)")
    
except Exception as e:
    print(f"Error generating summary: {e}")
END

# Show first few results
echo -e "\n=== SAMPLE RESULTS (first 5) ==="
head -6 staph_verification_results_fixed.csv | column -t -s,
