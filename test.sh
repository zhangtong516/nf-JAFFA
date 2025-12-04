====================================================================================================
###
 # @Author: Zhang Tong
 # @Email: zhangtong516@gmail.com
 # @Company: GIS
 # @Date: 2025-12-04 14:54:33
 # @LastEditors: Zhang Tong
 # @LastEditTime: 2025-12-04 14:54:37
### 

========================================= Stage run_check ==========================================

=============================== Stage get_fasta (RHH9512-T1_merged) ================================
java -ea -Xmx200m -cp /JAFFA/tools/bbmap/current/ jgi.ReformatReads \
    ignorebadquality=t \
    in=RHH9512-T1_merged.fastq.gz \
    out=RHH9512-T1_merged.fastq/RHH9512-T1_merged.fastq.fasta \
    threads=$threads

========================= Stage minimap2_transcriptome (RHH9512-T1_merged) =========================

minimap2 -t $threads -x map-ont \
    -c $transFasta \
    RHH9512-T1_merged.fastq/RHH9512-T1_merged.fastq.fasta \
    > $output1 

# Stage filter_transcripts (RHH9440-T1_merged)
/JAFFA/tools/bin/process_transcriptome_align_table RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.paf 1000 \
    /ref/hg38_genCode22.tab > RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.txt
# Stage extract_fusion_sequences (RHH9440-T1_merged)

# Stage extract_fusion_sequences (RHH9440-T1_merged)
cat RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.txt |\
    awk '{print $1}' > RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.fusions.fa.temp ;                 
/JAFFA/tools/bin/reformat in=RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.fasta out=stdout.fasta fastawrap=0 |\
    /JAFFA/tools/bin/extract_seq_from_fasta RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.fusions.fa.temp |\
        > RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.fusions.fa; 
rm RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.fusions.fa.temp ;

# Stage minimap2_genome (RHH9440-T1_merged)
/JAFFA/tools/bin/minimap2 -t 16 -x splice \
    -c /ref/hg38.fa \
    RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.fusions.fa \
    > RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq_genome.paf;         
grep $'\t+\t' RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq_genome.paf |\
    awk -F'\t' -v OFS="\t" '{ print $4-$3,0,0,0,0,0,0,0,$5,$1,$2,$3,$4,$6,$7,$8,$9,2, 100","$4-$3-100",",$3","$3+100",",  $8","$9-$4+$3+100"," }' > RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq_genome.psl ;         grep $'\t-\t' RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq_genome.paf | awk -F'\t' -v OFS="\t" '{ print $4-$3,0,0,0,0,0,0,0,$5,$1,$2,$3,$4,$6,$7,$8,$9,2, 100","$4-$3-100",", $2-$4","$2-$4+100",", $8","$9-$4+$3+100"," }' \
    >> RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq_genome.psl ;

# Stage make_fasta_reads_table (RHH9440-T1_merged)
echo  -e "transcript    break_min       break_max       fusion_genes    spanning_pairs  spanning_reads" \
    > RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.reads ;                  
awk '{ print $1" "$2"    "$3"    "$4"    "0"     "1}' RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.txt |\
    sort -u  >> RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.reads
# Stage get_final_list (RHH9440-T1_merged)
if [ ! -s RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq_genome.psl ] ; 
then 
    touch RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.summary ; 
else  
    /usr/bin/R --vanilla --args RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq_genome.psl \
        RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.reads \
        /ref/hg38_genCode22.tab \
        /JAFFA/known_fusions.txt  10000 \
        NoSupport,PotentialReadThrough 50 \
        RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.summary < /JAFFA/make_final_table.R ; 
fi;
# Stage report_3_gene_fusions (RHH9440-T1_merged)
/JAFFA/tools/bin/make_3_gene_fusion_table \
    RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.summary \
    RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.txt \
    RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.3gene_reads \
    > RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.3gene_summary

# Stage compile_all_results
/usr/bin/R --vanilla --args jaffa_results \
    RHH9440-T1_merged.fastq/RHH9440-T1_merged.fastq.summary \
    < /JAFFA/compile_results.R ; 
rm -f jaffa_results.fasta; 
while read line; do 
    /JAFFA/scripts/get_fusion_seqs.bash $line jaffa_results.fasta ; 
done < jaffa_results.csv;
echo "Done writing jaffa_results.fasta";
echo "All Done." ;
echo "*************************************************************************" ;
echo " Citation for JAFFA_direct, JAFFA_assembly and JAFFA_hybrid: " ;
echo "   Davidson, N.M., Majewski, I.J. & Oshlack, A. ";
echo "   JAFFA: High sensitivity transcriptome-focused fusion gene detection." ;
echo "   Genome Med 7, 43 (2015)" ;
echo "*************************************************************************" ;
echo " Citation for JAFFAL: " ;
echo "   Davidson, N.M. et al. ";
echo "   JAFFAL: detecting fusion genes with long-read transcriptome sequencing" ;
echo "   Genome Biol. 23, 10 (2022)" ;
echo "*************************************************************************" ;