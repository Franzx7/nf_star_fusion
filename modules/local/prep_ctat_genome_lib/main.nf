process PREP_CTAT_GENOME_LIB {
    tag "prep_ctat_genome_lib"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "community.wave.seqera.io/library/star-fusion:1.12.0--hdfd78af_0"

    input:
    path genome_fa
    path gtf
    path fusion_annot_lib

    output:
    path "ctat_genome_lib_build_dir", emit: lib
    path "versions.yml",             emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args       = task.ext.args ?: ''
    def annot_flag = fusion_annot_lib ? "--fusion_annot_lib ${fusion_annot_lib}" : ''
    """
    prep_genome_lib.pl \\
        --genome_fa ${genome_fa} \\
        --gtf ${gtf} \\
        ${annot_flag} \\
        --output_dir ctat_genome_lib_build_dir \\
        --CPU ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star-fusion: \$(STAR-Fusion --version 2>&1 | grep -oP 'STAR-Fusion_v\\K[0-9.]+' || echo "1.12.0")
    END_VERSIONS
    """

    stub:
    """
    mkdir -p ctat_genome_lib_build_dir
    touch ctat_genome_lib_build_dir/ref_genome.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star-fusion: 1.12.0
    END_VERSIONS
    """
}
