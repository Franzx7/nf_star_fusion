// Module: Generate STAR genome index

process STAR_INDEX {
    tag "STAR index for $genome_fasta"
    label 'xlarge'
    
    input:
    path genome_fasta
    path gtf
    
    output:
    path "star_index", emit: index
    
    script:
    """
    STAR --runMode genomeGenerate \\
        --runThreadN ${task.cpus} \\
        --genomeDir star_index \\
        --genomeFastaFiles ${genome_fasta} \\
        --sjdbGTFfile ${gtf} \\
        --sjdbOverhang 100 \\
        --limitGenomeGenerateRAM ${task.memory.toBytes() * 0.9}
    """
}
