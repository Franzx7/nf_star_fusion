process FUSION_INSPECTOR {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "community.wave.seqera.io/library/fusioninspector:2.8.0--hdfd78af_0"

    input:
    tuple val(meta), path(fusion_predictions), path(bam)
    tuple val(meta2), path(ctat_genome_lib)

    output:
    tuple val(meta), path("${prefix}.FusionInspector.fusions.tsv"),           emit: fusions
    tuple val(meta), path("${prefix}.FusionInspector.fusions.abridged.tsv"), emit: fusions_abridged
    tuple val(meta), path("${prefix}_fusion_inspector_outdir"),               emit: outdir
    path "versions.yml",                                                      emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    FusionInspector \\
        --fusion_predictions ${fusion_predictions} \\
        --genome_lib_dir ${ctat_genome_lib} \\
        --bam ${bam} \\
        --output_dir ${prefix}_fusion_inspector_outdir \\
        --CPU ${task.cpus} \\
        ${args}

    cp ${prefix}_fusion_inspector_outdir/FusionInspector.fusions.tsv ${prefix}.FusionInspector.fusions.tsv
    cp ${prefix}_fusion_inspector_outdir/FusionInspector.fusions.abridged.tsv ${prefix}.FusionInspector.fusions.abridged.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fusioninspector: \$(FusionInspector --version 2>&1 | grep -o 'FusionInspector-v[0-9.]*' | sed 's/FusionInspector-v//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${prefix}_fusion_inspector_outdir
    touch ${prefix}.FusionInspector.fusions.tsv
    touch ${prefix}.FusionInspector.fusions.abridged.tsv
    touch ${prefix}_fusion_inspector_outdir/FusionInspector.fusions.tsv
    touch ${prefix}_fusion_inspector_outdir/FusionInspector.fusions.abridged.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fusioninspector: \$(FusionInspector --version 2>&1 | grep -o 'FusionInspector-v[0-9.]*' | sed 's/FusionInspector-v//' || echo "2.8.0")
    END_VERSIONS
    """
}
