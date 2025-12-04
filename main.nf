#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/* main.nf now includes modular process definitions from `modules/`.
   The modules contain the process bodies; this file wires channels and launches the workflow. */

params.reads = "$PWD/*.fastq.gz"
params.sample = ''

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
    samples_ch.view() 
    // Process pipeline
    samples_ch | get_fasta | minimap2_transcriptome | filter_transcripts | make_fasta_reads_table
    
    // Ensure fasta channel exists for downstream extract_fusion_sequences
    fasta_ch.subscribe {}
    
    filter_transcripts | extract_fusion_sequences | minimap2_genome | get_final_list | report_3_gene_fusions | compile_all_results
}

workflow.onComplete {
    println "Pipeline finished with status: ${workflow.success ? 'SUCCESS' : 'FAILED'}"
}