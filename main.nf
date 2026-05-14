#!/usr/bin/env nextflow

/*
 * STAR-Fusion Analysis Pipeline
 * Main entry point
 *
 * Usage:
 *   nextflow run main.nf [options]
 *
 * For full docs: nextflow run main.nf --help
 */

nextflow.enable.dsl = 2

include { PREP_CTAT_GENOME_LIB } from './modules/local/prep_ctat_genome_lib/main'
include { STAR_FUSION }          from './modules/local/star/fusion/main'

def get_version() { return '1.0.0' }

def get_help_message() {
    return """
    ========================================
    STAR-Fusion Analysis Pipeline v${get_version()}
    ========================================

    Usage:
        nextflow run main.nf [options]

    Required (choose one input method):
        --samplesheet           CSV file with columns: sample_id,read1,read2
        --input_fastq_dir       Directory containing paired FASTQ files (*.fastq.gz)

    Required (choose one reference method):
        --ctat_genome_lib_dir   Path to pre-built CTAT genome library directory
        --genome_fa             Custom genome FASTA  (triggers CTAT lib build)
        --gtf_file              Custom genome GTF    (triggers CTAT lib build)
        --fusion_annot_lib      Fusion annotation library (optional, used with --genome_fa)

    Optional:
        --outdir                Output directory (default: ./results)
        --min_junction_reads    Minimum junction reads (default: 1)
        --min_spanning_frags    Minimum spanning fragments (default: 0)
        --help                  Show this help message

    Profiles:
        -profile singularity    Use Singularity containers (recommended on HPC)
        -profile docker         Use Docker containers
        -profile slurm          SLURM scheduler
        -profile test           Mini test dataset

    Examples:
        nextflow run main.nf \\
            --samplesheet samples.csv \\
            --ctat_genome_lib_dir /path/to/ctat_genome_lib_build_dir

        nextflow run main.nf \\
            --samplesheet samples.csv \\
            --genome_fa genome.fa --gtf_file genome.gtf \\
            --fusion_annot_lib CTAT_HumanFusionLib.dat.gz

        nextflow run main.nf -profile test

    See README.md for complete documentation.
    """.stripIndent()
}

workflow {

    if (params.help) {
        println get_help_message()
        exit 0
    }

    // Input validation
    if (!params.input_fastq_dir && !params.samplesheet) {
        error "Provide --samplesheet or --input_fastq_dir"
    }

    def build_ctat = params.genome_fa && params.gtf_file
    if (!build_ctat && !params.ctat_genome_lib_dir) {
        error "Provide --ctat_genome_lib_dir (pre-built) or --genome_fa + --gtf_file (to build)"
    }

    // Sample channel
    if (params.samplesheet) {
        samples = Channel
            .fromPath(params.samplesheet)
            .splitCsv(header: true)
            .map { row ->
                def meta = [id: row.sample_id]
                tuple(meta, [file(row.read1), file(row.read2)])
            }
    } else {
        // Supports: sample_R1.fastq.gz / sample_R2.fastq.gz
        //       and sample_1.fastq.gz  / sample_2.fastq.gz
        samples = Channel
            .fromFilePairs([
                "${params.input_fastq_dir}/*_{R1,R2}{.fq,.fastq}{,.gz}",
                "${params.input_fastq_dir}/*_{1,2}{.fq,.fastq}{,.gz}"
            ])
            .map { sample_id, reads ->
                def meta = [id: sample_id]
                tuple(meta, reads)
            }
    }

    // CTAT genome library
    if (build_ctat) {
        fusion_annot_lib = params.fusion_annot_lib
            ? Channel.fromPath(params.fusion_annot_lib)
            : Channel.value([])

        PREP_CTAT_GENOME_LIB(
            Channel.fromPath(params.genome_fa),
            Channel.fromPath(params.gtf_file),
            fusion_annot_lib
        )
        ctat_lib = PREP_CTAT_GENOME_LIB.out.lib
    } else {
        ctat_lib = Channel.fromPath(params.ctat_genome_lib_dir)
    }

    // STAR-Fusion: alignment + fusion detection + FusionInspector + coding effect
    STAR_FUSION(samples, ctat_lib)
}
