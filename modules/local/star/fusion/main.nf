process STAR_FUSION {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "community.wave.seqera.io/library/star-fusion:1.12.0--hdfd78af_0"

    input:
    tuple val(meta), path(reads)
    path ctat_genome_lib

    output:
    tuple val(meta), path("${prefix}_outdir/star-fusion.fusion_predictions.tsv"),                        emit: predictions
    tuple val(meta), path("${prefix}_outdir/star-fusion.fusion_predictions.abridged.tsv"),               emit: predictions_abridged
    tuple val(meta), path("${prefix}_outdir/star-fusion.fusion_predictions.abridged.coding_effect.tsv"), emit: coding_effect
    tuple val(meta), path("${prefix}_outdir/FusionInspector.fusions.tsv"),                               emit: inspector_fusions
    tuple val(meta), path("${prefix}_outdir/FusionInspector.fusions.abridged.tsv"),                      emit: inspector_fusions_abridged
    tuple val(meta), path("${prefix}_outdir"),                                                            emit: outdir
    path "versions.yml",                                                                                  emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    prefix     = task.ext.prefix ?: "${meta.id}"
    def read1  = reads[0]
    def read2  = reads[1]
    """
    STAR-Fusion \\
        --left_fq ${read1} \\
        --right_fq ${read2} \\
        --genome_lib_dir ${ctat_genome_lib} \\
        --FusionInspector validate \\
        --denovo_reconstruct \\
        --examine_coding_effect \\
        --output_dir ${prefix}_outdir \\
        --CPU ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star-fusion: \$(STAR-Fusion --version 2>&1 | grep -oP 'STAR-Fusion_v\\K[0-9.]+' || echo "1.12.0")
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_outdir
    touch ${prefix}_outdir/star-fusion.fusion_predictions.tsv
    touch ${prefix}_outdir/star-fusion.fusion_predictions.abridged.tsv
    touch ${prefix}_outdir/star-fusion.fusion_predictions.abridged.coding_effect.tsv
    touch ${prefix}_outdir/FusionInspector.fusions.tsv
    touch ${prefix}_outdir/FusionInspector.fusions.abridged.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star-fusion: 1.12.0
    END_VERSIONS
    """
}

