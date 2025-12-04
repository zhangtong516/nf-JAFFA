process get_fasta {
    tag "get_fasta:${sampleId}"
    publishDir "${params.outdir}/${sampleId}/jaffa_files/", mode: 'copy'
    cpus params.cpus?.get('get_final_list') ?: 2
    memory params.memory?.get('get_final_list') ?: '4 GB'

    container params.container?.get('bbmap') ?: ''

    input:
    tuple val(sampleId), path(reads)

    output:
    tuple val(sampleId), path("${sampleId}.reformated.fasta") into fasta_ch

    script:
    """
    reformat.sh ignorebadquality=t  \
        in=${reads} \
        out=${sampleId}.reformated.fasta \
        threads=${cpus}
    """
}
