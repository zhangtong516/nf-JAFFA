#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/* main.nf now includes modular process definitions from `modules/`.
   The modules contain the process bodies; this file wires channels and launches the workflow. */

params.reads = "$PWD/*.fastq.gz"
params.sample = ''
params.outdir = "./results/"


include { get_fasta } from './modules/get_fasta'
include { minimap2_transcriptome } from './modules/minimap2_transcriptome'
include { filter_transcripts } from './modules/filter_transcripts'
include { extract_fusion_sequences } from './modules/extract_fusion_sequences'
include { minimap2_genome } from './modules/minimap2_genome'
include { make_fasta_reads_table } from './modules/make_fasta_reads_table'
include { get_final_list } from './modules/get_final_list'
include { report_3_gene_fusions } from './modules/report_3_gene_fusions'
include { compile_all_results } from './modules/compile_all_results'

// Main workflow
workflow {
    // Create input channel
    Channel.fromPath(params.reads, checkIfExists: true)
        .ifEmpty { error "No input reads found with pattern: ${params.reads}" }
        .map { file -> tuple(file.baseName, file) }
        .set { samples_ch }
    
    // Process pipeline - capture outputs
    fasta_out = get_fasta(samples_ch)
    paf_tx_out = minimap2_transcriptome(fasta_out, Channel.fromPath(params.transFasta, checkIfExists: true)) 
    filtered_out = filter_transcripts(paf_tx_out)
    table_out = make_fasta_reads_table(filtered_out)
    
    // Branch to extract_fusion_sequences
    fusion_seqs = extract_fusion_sequences(filtered_out.join(fasta_out))
    genome_mapped = minimap2_genome(fusion_seqs, Channel.fromPath(params.refGenome, checkIfExists: true))
    final_list = get_final_list(genome_mapped.join(table_out), Channel.fromPath(params.refGeneTab, checkIfExists: true))
    report_out = report_3_gene_fusions(final_list.join(filtered_out))
    compile_all_results(report_out)
}

workflow.onComplete {
    println "Pipeline finished with status: ${workflow.success ? 'SUCCESS' : 'FAILED'}"
}