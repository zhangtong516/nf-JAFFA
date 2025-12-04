process make_fasta_reads_table {
    tag "make_reads_table:${sampleId}"
    publishDir "${params.outdir}/${sampleId}/jaffa_files/", mode: 'copy'
    cpus 1

    input:
    tuple val(sampleId), path(txt) from tx_txt_ch

    output:
    tuple val(sampleId), path("${sampleId}.reads"), emit: reads_table_ch

    script:
    """
    echo -e "transcript\tbreak_min\tbreak_max\tfusion_genes\tspanning_pairs\tspanning_reads" > ${sampleId}.reads
    awk '{ print \$1" "\$2"    "\$3"    "\$4"    "0"     "1}' ${txt} | sort -u >> ${sampleId}.reads
    """
}
