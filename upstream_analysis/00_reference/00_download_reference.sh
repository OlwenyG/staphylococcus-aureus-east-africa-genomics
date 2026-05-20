#!/bin/bash
#SBATCH --job-name=download_reference
#SBATCH --output=download_reference_%j.out
#SBATCH --error=download_reference_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=1:00:00
#SBATCH --partition=normal

source ~/.bashrc
conda activate bacterial-genomics-tutorial

mkdir -p references
cd references

echo "Downloading S. aureus reference genome..."

# Try multiple sources for S. aureus NCTC 8325 (well-annotated reference)
echo "Attempt 1: Downloading from NCBI RefSeq..."
wget -O saureus_ref.fasta.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/013/425/GCF_000013425.1_ASM1342v1/GCF_000013425.1_ASM1342v1_genomic.fna.gz" 2>/dev/null

if [ -f "saureus_ref.fasta.gz" ]; then
    echo "Extracting reference genome..."
    gunzip saureus_ref.fasta.gz
    echo "✓ Successfully downloaded from RefSeq"
else
    echo "Attempt 2: Trying direct NCBI nucleotide..."
    efetch -db nucleotide -id "NC_007795.1" -format fasta > saureus_ref.fasta 2>/dev/null
    
    if [ ! -s "saureus_ref.fasta" ]; then
        echo "Attempt 3: Trying alternative S. aureus strain..."
        wget -O saureus_ref.fasta "https://ftp.ncbi.nlm.nih.gov/genomes/refseq/bacteria/Staphylococcus_aureus/latest_assembly_versions/GCF_000013425.1_ASM1342v1/GCF_000013425.1_ASM1342v1_genomic.fna" 2>/dev/null
    fi
fi

# Verify download
if [ -s "saureus_ref.fasta" ]; then
    echo "✓ Successfully downloaded reference genome"
    echo "File size: $(du -h saureus_ref.fasta | cut -f1)"
    echo "Sequence length: $(grep -v ">" saureus_ref.fasta | tr -d '\n' | wc -c) bp"
    echo "Number of contigs: $(grep ">" saureus_ref.fasta | wc -l)"
    
    # Index the reference for BWA
    echo "Indexing reference genome for BWA..."
    bwa index saureus_ref.fasta
    samtools faidx saureus_ref.fasta
    
    echo "✓ Reference genome ready for mapping!"
else
    echo "✗ Failed to download reference genome from all sources"
    echo "Please check your internet connection or try manual download"
    exit 1
fi
