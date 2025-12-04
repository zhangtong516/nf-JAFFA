process filter_transcripts {
    tag "filter_tx:${sampleId}"
    publishDir "${params.outdir}/${sampleId}/jaffa_files/", mode: 'copy'
    cpus params.cpus?.get('filter_transcripts') ?: 2
    memory params.memory?.get('filter_transcripts') ?: '4 GB'
    
    input:
    tuple val(sampleId), path(paf)

    output:
    tuple val(sampleId), path("${sampleId}.txt") into tx_txt_ch

    script:
    """
    ${baseDir}/bin/process_transcriptome_align_table ${paf} 1000 ${params.refGeneTab} > ${sampleId}.txt
    """
}
