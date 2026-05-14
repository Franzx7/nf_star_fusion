// Module: Align RNA-seq reads with STAR

process STAR_ALIGN {
    tag "$sample_id"
    label 'xlarge'
    
    input:
    tuple val(sample_id), path(reads)
    path star_index
    
    output:
    tuple val(sample_id), path("${sample_id}.Aligned.sortedByCoord.out.bam"), emit: bam
    tuple val(sample_id), path("${sample_id}.Chimeric.out.junction"), emit: chimeric_junctions
    tuple val(sample_id), path("${sample_id}.SJ.out.tab"), emit: splice_junctions
    path "${sample_id}.Log.final.out", emit: log_final
    
    script:
    def input_reads = reads instanceof List ? reads.join(' ') : reads
    """
    STAR --runMode alignReads \\
        --runThreadN ${task.cpus} \\
        --genomeDir ${star_index} \\
        --readFilesIn ${input_reads} \\
        --readFilesCommand zcat \\
        --outFileNamePrefix ${sample_id}. \\
        --outSAMtype BAM SortedByCoordinate \\
        --outSAMunmapped Within \\
        --chimOutType Junctions \\
        --chimSegmentMin 12 \\
        --chimJunctionOverhangMin 12 \\
        --chimOutJunctionFormat 1 \\
        --limitBAMsortRAM ${task.memory.toBytes() * 0.9}
    """
}
