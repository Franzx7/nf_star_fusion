process STAR_FUSION {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "community.wave.seqera.io/library/star-fusion:1.12.0--hdfd78af_0"

    input:
    tuple val(meta), path(chimeric_junctions), path(bam)
    tuple val(meta2), path(ctat_genome_lib)

    output:
    tuple val(meta), path("${prefix}.star-fusion.fusion_predictions.tsv"),           emit: predictions
    tuple val(meta), path("${prefix}.star-fusion.fusion_predictions.abridged.tsv"), emit: predictions_abridged
    tuple val(meta), path("${prefix}_star_fusion_outdir"),                           emit: outdir
    path "versions.yml",                                                             emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    STAR-Fusion \\
        --genome_lib_dir ${ctat_genome_lib} \\
        --chimeric_junction ${chimeric_junctions} \\
        --output_dir ${prefix}_star_fusion_outdir \\
        --CPU ${task.cpus} \\
        ${args}

    cp ${prefix}_star_fusion_outdir/star-fusion.fusion_predictions.tsv ${prefix}.star-fusion.fusion_predictions.tsv
    cp ${prefix}_star_fusion_outdir/star-fusion.fusion_predictions.abridged.tsv ${prefix}.star-fusion.fusion_predictions.abridged.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star-fusion: \$(STAR-Fusion --version 2>&1 | grep -o 'STAR-Fusion-v[0-9.]*' | sed 's/STAR-Fusion-v//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${prefix}_star_fusion_outdir
    touch ${prefix}.star-fusion.fusion_predictions.tsv
    touch ${prefix}.star-fusion.fusion_predictions.abridged.tsv
    touch ${prefix}_star_fusion_outdir/star-fusion.fusion_predictions.tsv
    touch ${prefix}_star_fusion_outdir/star-fusion.fusion_predictions.abridged.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star-fusion: \$(STAR-Fusion --version 2>&1 | grep -o 'STAR-Fusion-v[0-9.]*' | sed 's/STAR-Fusion-v//' || echo "1.12.0")
    END_VERSIONS
    """
}
