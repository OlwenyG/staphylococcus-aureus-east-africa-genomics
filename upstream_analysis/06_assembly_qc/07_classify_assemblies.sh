#!/bin/bash
echo -e "Sample\tContigs\tTotalLength(Mbp)\tStatus\tNotes"
for file in *_contigs.fasta; do
    sample=$(basename "$file" _contigs.fasta)
    contigs=$(grep -c ">" "$file")
    total_length=$(awk '/^>/ {if (seqlen) total+=seqlen; seqlen=0; next} {seqlen += length($0)} END {total+=seqlen; print total}' "$file")
    length_mbp=$(echo "scale=2; $total_length/1000000" | bc)
    
    if (( total_length > 6000000 )); then
        status="CONTAMINATED"
        notes="Oversized (>6Mbp)"
    elif (( contigs > 500 )); then
        status="FRAGMENTED" 
        notes="High contig count"
    elif (( total_length < 2000000 )); then
        status="INCOMPLETE"
        notes="Undersized (<2Mbp)"
    else
        status="GOOD"
        notes="Normal bacterial genome"
    fi
    
    echo -e "$sample\t$contigs\t$length_mbp\t$status\t$notes"
done
