process MULTIQC {
    tag "MultiQC Report"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "community.wave.seqera.io/library/multiqc:1.24--hdfd78af_0"

    input:
    path(qc_files)
    path(log_files)

    output:
    path "multiqc_report.html", emit: report
    path "multiqc_data",        emit: data
    path "versions.yml",        emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    multiqc $args .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed 's/multiqc, version //' )
    END_VERSIONS
    """

    stub:
    """
    touch multiqc_report.html
    mkdir multiqc_data
    touch multiqc_data/multiqc.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: 1.24
    END_VERSIONS
    """
}
