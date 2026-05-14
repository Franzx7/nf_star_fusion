#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Import modules
include { STAR_INDEX } from '../modules/star_index'
include { STAR_ALIGN } from '../modules/star_align'
include { STAR_FUSION } from '../modules/star_fusion'
include { FUSION_INSPECTOR } from '../modules/fusion_inspector'
include { FASTQC } from '../modules/qc'
include { MULTIQC } from '../modules/qc'

// Define workflow version and metadata
def get_version() {
    return '1.0.0'
}

def get_help_message() {
    return """
    ========================================
    STAR-Fusion Analysis Pipeline v${get_version()}
    ========================================
    
    Usage:
        nextflow run workflows/main.nf [options]
    
    Required arguments:
        --input_fastq_dir       Directory containing FASTQ files (paired-end, gzipped)
        --ctat_genome_lib_dir   Path to CTAT genome library directory
        --genome_fa             Genome FASTA file (if building index)
        --gtf_file              Gene annotation GTF file (if building index)
    
    Optional arguments:
        --samplesheet           CSV file with columns: sample_id,read1,read2
        --outdir                Output directory (default: ./results)
        --skip_fastqc           Skip FastQC analysis
        --skip_multiqc          Skip MultiQC aggregation
        --min_junction_reads    Minimum junction reads for fusion calls (default: 1)
        --min_spanning_frags    Minimum spanning fragments (default: 0)
        --star_threads          Number of STAR threads (default: 8)
    
    Execution profiles:
        -profile docker         Use Docker containers
        -profile singularity    Use Singularity containers
        -profile slurm          Use SLURM scheduler
        -profile local          Use local execution
    
    Examples:
        # Run with Docker on local machine
        nextflow run workflows/main.nf \\
            -profile docker \\
            --input_fastq_dir ./data/fastqs \\
            --ctat_genome_lib_dir ./references/CTAT_LR \\
            --outdir ./results
        
        # Run on HPC with SLURM
        nextflow run workflows/main.nf \\
            -profile slurm,docker \\
            --input_fastq_dir ./data/fastqs \\
            --ctat_genome_lib_dir ./references/CTAT_LR \\
            --outdir ./results
    """.stripIndent()
}

// Print help and exit
if (params.help) {
    println get_help_message()
    exit 0
}

// Validate required inputs
if (!params.input_fastq_dir && !params.samplesheet) {
    println "ERROR: Either --input_fastq_dir or --samplesheet is required"
    exit 1
}

if (!params.ctat_genome_lib_dir) {
    println "ERROR: --ctat_genome_lib_dir is required"
    exit 1
}

// Create output directory
outdir_path = file(params.outdir)
if (!outdir_path.exists()) {
    outdir_path.mkdirs()
}

// Define main workflow
workflow {
    
    // Create input channel from FASTQ directory or samplesheet
    if (params.samplesheet) {
        // Parse samplesheet
        samples = Channel
            .fromPath(params.samplesheet)
            .splitCsv(header: true)
            .map { row -> 
                tuple(
                    row.sample_id,
                    [file(row.read1), file(row.read2)]
                )
            }
    } else {
        // Discover FASTQ files from directory
        samples = Channel
            .fromFilePairs("${params.input_fastq_dir}/*{R1,_1,_R1}{.fq.gz,.fastq.gz}")
            .map { sample_id, reads -> 
                tuple(sample_id, reads)
            }
    }
    
    // Generate STAR index if genome files provided
    if (params.genome_fa && params.gtf_file) {
        genome_fa = Channel.fromPath(params.genome_fa)
        gtf = Channel.fromPath(params.gtf_file)
        
        STAR_INDEX(genome_fa, gtf)
        star_index = STAR_INDEX.out.index
    } else {
        // Use existing CTAT genome library which includes STAR index
        star_index = Channel.fromPath(params.ctat_genome_lib_dir)
    }
    
    // Run FastQC for QC
    if (!params.skip_fastqc) {
        FASTQC(samples)
        fastqc_out = FASTQC.out.zip.collect()
    } else {
        fastqc_out = Channel.empty()
    }
    
    // Align reads with STAR
    STAR_ALIGN(samples, star_index)
    
    // Run STAR-Fusion on chimeric junctions and BAM files
    ctat_lib = Channel.fromPath(params.ctat_genome_lib_dir)
    
    STAR_FUSION(
        STAR_ALIGN.out.chimeric_junctions.join(STAR_ALIGN.out.bam),
        ctat_lib
    )
    
    // Validate fusions with FusionInspector
    FUSION_INSPECTOR(
        STAR_FUSION.out.predictions.join(STAR_ALIGN.out.bam),
        ctat_lib
    )
    
    // Run MultiQC if not skipped
    if (!params.skip_multiqc) {
        MULTIQC(
            FASTQC.out.zip.collect(),
            STAR_ALIGN.out.log_final.collect()
        )
    }
}

// Completion handler
workflow.onComplete {
    println """
    ========================================
    Pipeline completed successfully!
    ========================================
    Results saved to: ${params.outdir}
    
    Key output files:
    - Fusion predictions: results/star_fusion/*.tsv
    - Validated fusions: results/fusion_inspector/*.final
    - Quality reports: results/multiqc/multiqc_report.html
    - Execution report: results/execution_report.html
    - Pipeline DAG: results/pipeline_dag.html
    """.stripIndent()
}

workflow.onError {
    println """
    ========================================
    Pipeline failed!
    ========================================
    Error message:
    ${workflow.errorMessage}
    """
}
