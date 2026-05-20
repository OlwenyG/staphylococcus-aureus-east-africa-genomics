#!/bin/bash
#SBATCH --job-name=fastqc_overview
#SBATCH --output=fastqc_overview_%j.out
#SBATCH --error=fastqc_overview_%j.err
#SBATCH --cpus-per-task=16
#SBATCH --mem=20G
#SBATCH --time=6:00:00
#SBATCH --partition=normal

source ~/.bashrc
conda activate bacterial-genomics-tutorial

# Navigate to fastq_files directory
cd fastq_files

# Create directories for reports
mkdir -p ../fastqc_reports ../multiqc_report

echo "Starting FastQC analysis of $(ls *.fastq.gz | wc -l) files..."

# Run FastQC on all FASTQ files
fastqc *.fastq.gz -o ../fastqc_reports -t 16

echo "FastQC complete. Generating MultiQC report..."

# Generate comprehensive MultiQC report
multiqc ../fastqc_reports/ -o ../multiqc_report -f

echo "=== QUALITY ASSESSMENT COMPLETE ==="
echo "Main report: ../multiqc_report/multiqc_report.html"
echo "Individual reports: ../fastqc_reports/"
echo ""
echo "Total files processed: $(ls *.fastq.gz | wc -l)"
