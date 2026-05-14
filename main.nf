#!/usr/bin/env nextflow

/*
 * STAR-Fusion Analysis Pipeline
 * Main entry point
 *
 * Usage:
 *   nextflow run . [options]
 *   nextflow run main.nf [options]
 *
 * For full docs: nextflow run . --help
 */

nextflow.enable.dsl = 2

// Import all modules
include { STAR_INDEX }       from './modules/star_index'
include { STAR_ALIGN }       from './modules/star_align'
include { STAR_FUSION }      from './modules/star_fusion'
include { FUSION_INSPECTOR } from './modules/fusion_inspector'
include { FASTQC; MULTIQC }  from './modules/qc'

// Version
def get_version() { return '1.0.0' }

def get_help_message() {
    return """
    ========================================
    STAR-Fusion Analysis Pipeline v${get_version()}
    ========================================

    Usage:
        nextflow run . [options]
        nextflow run main.nf [options]

    Required arguments:
        --input_fastq_dir       Directory containing FASTQ files (paired-end, gzipped)
        --ctat_genome_lib_dir   Path to CTAT genome library directory

    Optional arguments:
        --samplesheet           CSV file with columns: sample_id,read1,read2
        --genome_fa             Genome FASTA (if building custom index)
        --gtf_file              Gene annotation GTF (if building custom index)
        --outdir                Output directory (default: ./results)
        --skip_fastqc           Skip FastQC analysis
        --skip_multiqc          Skip MultiQC aggregation
        --min_junction_reads    Minimum junction reads (default: 1)
        --min_spanning_frags    Minimum spanning fragments (default: 0)

    Execution profiles:
        -profile docker         Use Docker containers (recommended)
        -profile singularity    Use Singularity containers
        -profile slurm          Use SLURM scheduler
        -profile sge            Use Sun Grid Engine
        -profile local          Local execution (no containers)

    Examples:
        # Local with Docker
        nextflow run . -profile docker \\
            --input_fastq_dir ./data/fastqs \\
            --ctat_genome_lib_dir ./references/CTAT_LR

        # On HPC with SLURM
        nextflow run . -profile slurm,docker \\
            --samplesheet samples.csv \\
            --ctat_genome_lib_dir /shared/CTAT_LR

    See README.md for complete documentation
    """.stripIndent()
}

// Main workflow
workflow {

    // Help message
    if (params.help) {
        println get_help_message()
        exit 0
    }

    // Validate inputs
    if (!params.input_fastq_dir && !params.samplesheet) {
        error "Either --input_fastq_dir or --samplesheet is required"
    }

    if (!params.ctat_genome_lib_dir) {
        error "--ctat_genome_lib_dir is required"
    }

    // Create input channel
    if (params.samplesheet) {
        samples = Channel
            .fromPath(params.samplesheet)
            .splitCsv(header: true)
            .map { row -> tuple(row.sample_id, [file(row.read1), file(row.read2)]) }
    } else {
        samples = Channel
            .fromFilePairs("${params.input_fastq_dir}/*{R1,_1,_R1}{.fq.gz,.fastq.gz}")
            .map { sample_id, reads -> tuple(sample_id, reads) }
    }

    // STAR index
    if (params.genome_fa && params.gtf_file) {
        STAR_INDEX(Channel.fromPath(params.genome_fa), Channel.fromPath(params.gtf_file))
        star_index = STAR_INDEX.out.index
    } else {
        star_index = Channel.fromPath(params.ctat_genome_lib_dir)
    }

    // FastQC
    if (!params.skip_fastqc) {
        FASTQC(samples)
        fastqc_out = FASTQC.out.zip.collect()
    } else {
        fastqc_out = Channel.empty()
    }

    // STAR alignment
    STAR_ALIGN(samples, star_index)

    // STAR-Fusion
    STAR_FUSION(
        STAR_ALIGN.out.chimeric_junctions.join(STAR_ALIGN.out.bam),
        Channel.fromPath(params.ctat_genome_lib_dir)
    )

    // FusionInspector
    FUSION_INSPECTOR(
        STAR_FUSION.out.predictions.join(STAR_ALIGN.out.bam),
        Channel.fromPath(params.ctat_genome_lib_dir)
    )

    // MultiQC
    if (!params.skip_multiqc) {
        MULTIQC(
            FASTQC.out.zip.collect(),
            STAR_ALIGN.out.log_final.collect()
        )
    }
}

