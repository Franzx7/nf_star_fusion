process STAR_ALIGN {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "community.wave.seqera.io/library/star:2.7.11a--h0033a41_0"

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(index)

    output:
    tuple val(meta), path("${prefix}.Aligned.sortedByCoord.out.bam"), emit: bam
    tuple val(meta), path("${prefix}.Chimeric.out.junction"),         emit: chimeric_junctions
    tuple val(meta), path("${prefix}.SJ.out.tab"),                   emit: splice_junctions
    tuple val(meta), path("${prefix}.Log.final.out"),                emit: log_final
    tuple val(meta), path("${prefix}.Log.out"),                      emit: log_out
    tuple val(meta), path("${prefix}.Log.progress.out"),             emit: log_progress
    path "versions.yml",                                              emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input_reads = reads instanceof List ? reads.join(' ') : reads
    """
    STAR \\
        --runMode alignReads \\
        --runThreadN ${task.cpus} \\
        --genomeDir ${index} \\
        --readFilesIn ${input_reads} \\
        --readFilesCommand zcat \\
        --outFileNamePrefix ${prefix}. \\
        --outSAMtype BAM SortedByCoordinate \\
        --outSAMunmapped Within \\
        --chimOutType Junctions \\
        --chimSegmentMin 12 \\
        --chimJunctionOverhangMin 12 \\
        --chimOutJunctionFormat 1 \\
        --limitBAMsortRAM ${task.memory.toBytes() * 0.9 as Long} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version | sed -e "s/STAR_//g")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.Aligned.sortedByCoord.out.bam
    touch ${prefix}.Chimeric.out.junction
    touch ${prefix}.SJ.out.tab
    touch ${prefix}.Log.final.out
    touch ${prefix}.Log.out
    touch ${prefix}.Log.progress.out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version | sed -e "s/STAR_//g")
    END_VERSIONS
    """
}
