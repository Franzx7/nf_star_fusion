// Module: Validate fusions with FusionInspector

process FUSION_INSPECTOR {
    tag "$sample_id"
    label 'large'
    
    input:
    tuple val(sample_id), path(fusion_predictions), path(bam)
    path ctat_genome_lib
    
    output:
    tuple val(sample_id), path("${sample_id}.finspector.fusion_predictions.final"), emit: final_predictions
    tuple val(sample_id), path("${sample_id}.finspector.fusion_predictions.final.abridged"), emit: final_predictions_abridged, optional: true
    path "${sample_id}.finspector*/", emit: finspector_dir, optional: true
    
    script:
    """
    FusionInspector \\
        --fusion_predictions ${fusion_predictions} \\
        --genome_lib_dir ${ctat_genome_lib} \\
        --bam ${bam} \\
        --fusions_vcf \\
        --out_prefix ${sample_id}.finspector \\
        --output_dir . \\
        -T ${task.cpus}
    
    # Ensure output files exist
    if [ -f finspector.fusion_predictions.final ]; then
        mv finspector.fusion_predictions.final ${sample_id}.finspector.fusion_predictions.final
    fi
    
    if [ -f finspector.fusion_predictions.final.abridged ]; then
        mv finspector.fusion_predictions.final.abridged ${sample_id}.finspector.fusion_predictions.final.abridged
    fi
    """
}
