process minimap2_genome {
    tag "minimap2_genome:${sampleId}"
    publishDir "${params.outdir}/${sampleId}/jaffa_files/", mode: 'copy'
    cpus params.cpus?.get('minimap2_genome') ?: 16
    memory params.memory?.get('minimap2_genome') ?: '64 GB'
    container params.container?.get('minimap2') ?: ''

    input:
    tuple val(sampleId), path(fusions)

    output:
    tuple val(sampleId), path("${sampleId}_genome.paf"), emit: paf_genome_ch

    script:
    """
    minimap2 -t ${cpus} -x splice -c ${params.refGenome} ${fusions} > ${sampleId}_genome.paf
    """
}
