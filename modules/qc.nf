// Module: Quality control with FastQC

process FASTQC {
    tag "$sample_id"
    label 'small'
    
    input:
    tuple val(sample_id), path(reads)
    
    output:
    path "${sample_id}_*_fastqc.html", emit: html
    path "${sample_id}_*_fastqc.zip", emit: zip
    
    script:
    def input_files = reads instanceof List ? reads.join(' ') : reads
    """
    fastqc \\
        -t ${task.cpus} \\
        -q \\
        ${input_files}
    """
}

// Module: Aggregate QC reports with MultiQC

process MULTIQC {
    tag "MultiQC Report"
    label 'small'
    
    publishDir "${params.outdir}/multiqc", mode: 'copy'
    
    input:
    path('fastqc/*')
    path('alignment/*')
    
    output:
    path "multiqc_report.html", emit: report
    path "multiqc_data", emit: data
    
    script:
    """
    multiqc \\
        -n multiqc_report.html \\
        -o . \\
        fastqc alignment
    """
}
