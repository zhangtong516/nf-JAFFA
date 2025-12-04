process report_3_gene_fusions {
    tag "report_3gene:${sampleId}"
    publishDir  "${params.outdir}/${sampleId}/jaffa_files/", mode: 'copy'
    

    input:
    tuple val(sampleId), path(summary) from summary_ch
    tuple val(_, path(txt)) from tx_txt_ch.filter{ it[0]==sampleId }

    output:
    tuple val(sampleId), path("${sampleId}.3gene_summary") into report_ch

    script:
    """
    ${baseDir}/bin/make_3_gene_fusion_table \
        ${summary} \
        ${txt} \
        ${sampleId}.3gene_reads > ${sampleId}.3gene_summary
    """
}
