process extract_fusion_sequences {
    tag "extract_fusions:${sampleId}"
    publishDir "${params.outdir}/${sampleId}/jaffa_files/", mode: 'copy'
    cpus params.cpus?.get('extract_fusion_sequences') ?: 2
    memory params.memory?.get('extract_fusion_sequences') ?: '8 GB'
    container params.container?.get('bbmap') ?: ''

    input:
    tuple val(sampleId), path(txt)
    tuple val(_, path(fasta)) from fasta_ch.filter{ it[0]==txt.baseName }

    output:
    tuple val(sampleId), path("${sampleId}.fusions.fa") , emit: fusions_fa_ch

    script:
    """
    awk '{print \$1}' ${txt} > ${sampleId}.fusions.fa.temp
    reformat.sh in=${fasta} out=stdout.fasta fastawrap=0 | \
      ${baseDir}/bin/extract_seq_from_fasta ${sampleId}.fusions.fa.temp > ${sampleId}.fusions.fa
    rm -f ${sampleId}.fusions.fa.temp
    """
}
