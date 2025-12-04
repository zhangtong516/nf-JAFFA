process compile_all_results {
    tag "compile_results:${sampleId}"
    publishDir "./results/${sampleId}", mode: 'copy'
    cpus 1
    container params.container?.get('r_base') ?: ''

    input:
    tuple val(sampleId), path(summary) from summary_ch

    output:
    path("jaffa_results.fasta") optional true

    script:
    """
    /usr/bin/R --vanilla --args jaffa_results ${summary} < ${baseDir}/bin/compile_results.R
    rm -f jaffa_results.fasta
    while read line; do
      ${baseDir}/bin/get_fusion_seqs.bash \$line jaffa_results.fasta
    done < jaffa_results.csv || true

    echo "Done writing jaffa_results.fasta"
    """
}
