// Module: Detect fusion transcripts with STAR-Fusion

process STAR_FUSION {
    tag "$sample_id"
    label 'large'
    
    input:
    tuple val(sample_id), path(chimeric_junctions), path(bam)
    path ctat_genome_lib
    
    output:
    tuple val(sample_id), path("${sample_id}.star-fusion.fusion_predictions.tsv"), emit: predictions
    tuple val(sample_id), path("${sample_id}.star-fusion.fusion_predictions.abridged.tsv"), emit: predictions_abridged
    path "${sample_id}.star-fusion.fusion_predictions.abridged.coding_effect.tsv", emit: coding_effect, optional: true
    
    script:
    """
    STAR-Fusion \\
        --genome_lib_dir ${ctat_genome_lib} \\
        --chimeric_junction ${chimeric_junctions} \\
        --bam ${bam} \\
        --output_dir . \\
        --CPU ${task.cpus} \\
        --min_junction_reads ${params.min_junction_reads} \\
        --min_spanning_frags ${params.min_spanning_frags}
    
    # Rename output files to include sample ID
    mv star-fusion.fusion_predictions.tsv ${sample_id}.star-fusion.fusion_predictions.tsv || true
    mv star-fusion.fusion_predictions.abridged.tsv ${sample_id}.star-fusion.fusion_predictions.abridged.tsv || true
    mv star-fusion.fusion_predictions.abridged.coding_effect.tsv ${sample_id}.star-fusion.fusion_predictions.abridged.coding_effect.tsv || true
    """
}
