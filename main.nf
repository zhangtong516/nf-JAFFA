#!/usr/bin/env nextflow

/* main.nf now includes modular process definitions from `modules/`.
   The modules contain the process bodies; this file wires channels and launches the workflow. */

params.reads = "$PWD/*.fastq.gz"
params.sample = ''


workflow.onComplete { status ->
    println "Pipeline finished with status: ${status}"
}

Channel.fromPath(params.reads, checkIfExists: true)
    .ifEmpty { error "No input reads found with pattern: ${params.reads}" }
    .map { file -> tuple(file.baseName, file) }
    .set { samples_ch }

include { get_fasta } from './modules/get_fast'
include { minimap2_transcriptome } from './modules/minimap2_transcriptom'
include { filter_transcripts } from './modules/filter_transcript'
include { extract_fusion_sequences } from './modules/extract_fusion_sequence'
include { minimap2_genome } from './modules/minimap2_genom'
include { make_fasta_reads_table } from './modules/make_fasta_reads_tabl'
include { get_final_list } from './modules/get_final_list'
include { report_3_gene_fusions } from './modules/report_3_gene_fusion'
include { compile_all_results } from './modules/compile_all_result'

// Wiring the channels: processes are modularized in `modules/` and emit/consume
// the channels named below (e.g. `fasta_ch`, `paf_tx_ch`, `tx_txt_ch`, ...)
samples_ch | get_fasta | minimap2_transcriptome | filter_transcripts | make_fasta_reads_table

// ensure fasta channel exists for downstream extract_fusion_sequences
fasta_ch.subscribe {}

filter_transcripts | extract_fusion_sequences | minimap2_genome | get_final_list | report_3_gene_fusions | compile_all_results

