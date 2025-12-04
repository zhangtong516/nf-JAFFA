process minimap2_transcriptome {
    tag "minimap2_tx:${sampleId}"
    publishDir "${params.outdir}/${sampleId}/jaffa_files/", mode: 'copy'
    cpus params.cpus?.get('minimap2_transcriptome') ?: 16
    memory params.memory?.get('minimap2_transcriptome') ?: '48 GB'
    container params.container?.get('minimap2') ?: ''

    input:
    tuple val(sampleId), path(fasta)

    output:
    tuple val(sampleId), path("${sampleId}.paf"), emit: paf_tx_ch

    script:
    """
    minimap2 -t ${task.cpus} -x map-ont -c ${params.transFasta} ${fasta} > ${sampleId}.paf
    """
}
