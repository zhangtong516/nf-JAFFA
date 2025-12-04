process get_final_list {
    tag "get_final_list:${sampleId}"
    publishDir "./results/${sampleId}/", mode: 'copy'
    cpus params.cpus?.get('get_final_list') ?: 2
    memory params.memory?.get('get_final_list') ?: '4 GB'
    container params.container?.get('r_base') ?: ''

    input:
    tuple val(sampleId), path(psl) from paf_genome_ch.combine(reads_table_ch)

    output:
    tuple val(sampleId), path("${sampleId}.summary") , emit: summary_ch

    script:
    """
    if [ ! -s ${psl} ]; then
      touch ${sampleId}.summary
    else
      /usr/bin/R --vanilla --args ${psl} \
        ${sampleId}.reads \
        ${params.refGeneTab} \
        ${baseDir}/resources/known_fusions.txt \
        10000 \
        NoSupport,PotentialReadThrough \
        50 \
        ${sampleId}.summary < ${baseDir}/bin/make_final_table.R
    fi
    """
}
