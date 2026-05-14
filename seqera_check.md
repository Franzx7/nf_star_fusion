

# Seqer AI instruction for a compliant repo


Nextflow Pipeline Compliance Migration Guide
Overview
This document provides a comprehensive guide to update your STAR-Fusion pipeline to comply with the most updated Nextflow guidelines. The migration involves restructuring modules, updating configurations, and implementing modern best practices.

Current vs. Recommended Structure
Current Structure

modules/
├── star_align.nf
├── star_fusion.nf
├── fusion_inspector.nf
├── star_index.nf
└── qc.nf

Recommended Structure

my_rnaseq_pipeline/
├── main.nf
├── nextflow.config
├── modules/
│   └── local/
│       ├── star/
│       │   ├── align/
│       │   │   ├── main.nf
│       │   │   ├── meta.yml
│       │   │   └── environment.yml
│       │   ├── index/
│       │   │   ├── main.nf
│       │   │   ├── meta.yml
│       │   │   └── environment.yml
│       │   └── fusion/
│       │       ├── main.nf
│       │       ├── meta.yml
│       │       └── environment.yml
│       ├── fusioninspector/
│       │   ├── main.nf
│       │   ├── meta.yml
│       │   └── environment.yml
│       ├── fastqc/
│       │   ├── main.nf
│       │   ├── meta.yml
│       │   └── environment.yml
│       └── multiqc/
│           ├── main.nf
│           ├── meta.yml
│           └── environment.yml
├── workflows/
│   └── star_fusion.nf
├── conf/
│   ├── base.config
│   ├── modules.config
│   └── test.config
├── tests/
│   ├── modules/
│   └── workflows/
└── assets/
    └── samplesheet.csv

Implementation Steps
1. Create Directory Structure

# Navigate to your repository
cd nf_star_fusion

# Create new directory structure
mkdir -p modules/local/star/{align,index,fusion}
mkdir -p modules/local/{fusioninspector,fastqc,multiqc}
mkdir -p workflows
mkdir -p conf
mkdir -p tests/modules/local/star/{align,index,fusion}
mkdir -p tests/modules/local/{fusioninspector,fastqc,multiqc}
mkdir -p tests/workflows
mkdir -p assets

# Backup current modules
cp -r modules modules_backup

2. Updated Module Files

modules/local/star/align/main.nf
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
    def args = task.ext.args ?: ''
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

modules/local/star/align/environment.yml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/nf-core/modules/master/modules/environment-schema.json
channels:
  - conda-forge
  - bioconda
dependencies:
  - "bioconda::star=2.7.11a"

modules/local/star/align/meta.yml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/nf-core/modules/master/modules/meta-schema.json
name: "star_align"
description: "Align RNA-seq reads to a reference genome using STAR"
keywords:
  - alignment
  - map
  - fastq
  - bam
  - sam
  - star
  - rna-seq
tools:
  - "star":
      description: "Spliced Transcripts Alignment to a Reference"
      homepage: "https://github.com/alexdobin/STAR"
      documentation: "https://github.com/alexdobin/STAR/blob/master/doc/STARmanual.pdf"
      tool_dev_url: "https://github.com/alexdobin/STAR"
      doi: "10.1093/bioinformatics/bts635"
      licence: ["MIT"]
      identifier: biotools:star

input:
  - - meta:
        type: map
        description: |
          Groovy Map containing sample information
          e.g. `[ id:'sample1', single_end:false ]`
    - reads:
        type: file
        description: |
          List of input FastQ files of size 1 and 2 for single-end and paired-end data,
          respectively.
        pattern: "*.{fq,fastq,fq.gz,fastq.gz}"
  - - meta2:
        type: map
        description: |
          Groovy Map containing reference information
          e.g. `[ id:'genome' ]`
    - index:
        type: directory
        description: STAR genome index
        pattern: "star"

output:
  - bam:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'sample1', single_end:false ]`
      - "*.bam":
          type: file
          description: Output BAM file containing read alignments
          pattern: "*.{bam}"
  - chimeric_junctions:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'sample1', single_end:false ]`
      - "*.Chimeric.out.junction":
          type: file
          description: Chimeric junction output from STAR
          pattern: "*.Chimeric.out.junction"
  - splice_junctions:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'sample1', single_end:false ]`
      - "*.SJ.out.tab":
          type: file
          description: Splice junction output from STAR
          pattern: "*.SJ.out.tab"
  - log_final:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'sample1', single_end:false ]`
      - "*.Log.final.out":
          type: file
          description: STAR final log file
          pattern: "*.Log.final.out"
  - log_out:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'sample1', single_end:false ]`
      - "*.Log.out":
          type: file
          description: STAR log file
          pattern: "*.Log.out"
  - log_progress:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'sample1', single_end:false ]`
      - "*.Log.progress.out":
          type: file
          description: STAR log progress file
          pattern: "*.Log.progress.out"
  - versions:
      - "versions.yml":
          type: file
          description: File containing software versions
          pattern: "versions.yml"

authors:
  - "@Franzx7"
maintainers:
  - "@Franzx7"

modules/local/star/index/main.nf
process STAR_INDEX {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "community.wave.seqera.io/library/star:2.7.11a--h0033a41_0"

    input:
    tuple val(meta), path(fasta)
    tuple val(meta2), path(gtf)

    output:
    tuple val(meta), path("star"), emit: index
    path "versions.yml",           emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def memory = task.memory ? "--limitGenomeGenerateRAM ${task.memory.toBytes() - 100000000}" : ''
    """
    mkdir star
    STAR \\
        --runMode genomeGenerate \\
        --genomeDir star/ \\
        --genomeFastaFiles ${fasta} \\
        --sjdbGTFfile ${gtf} \\
        --runThreadN ${task.cpus} \\
        --sjdbOverhang 100 \\
        ${memory} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version | sed -e "s/STAR_//g")
    END_VERSIONS
    """

    stub:
    """
    mkdir star
    touch star/chrLength.txt
    touch star/chrNameLength.txt
    touch star/chrName.txt
    touch star/chrStart.txt
    touch star/Genome
    touch star/genomeParameters.txt
    touch star/SA
    touch star/SAindex

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version | sed -e "s/STAR_//g")
    END_VERSIONS
    """
}

modules/local/star/index/environment.yml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/nf-core/modules/master/modules/environment-schema.json
channels:
  - conda-forge
  - bioconda
dependencies:
  - "bioconda::star=2.7.11a"

modules/local/star/index/meta.yml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/nf-core/modules/master/modules/meta-schema.json
name: "star_index"
description: "Generate STAR genome index"
keywords:
  - index
  - genome
  - reference
  - star
  - rna-seq
tools:
  - "star":
      description: "Spliced Transcripts Alignment to a Reference"
      homepage: "https://github.com/alexdobin/STAR"
      documentation: "https://github.com/alexdobin/STAR/blob/master/doc/STARmanual.pdf"
      tool_dev_url: "https://github.com/alexdobin/STAR"
      doi: "10.1093/bioinformatics/bts635"
      licence: ["MIT"]
      identifier: biotools:star

input:
  - - meta:
        type: map
        description: |
          Groovy Map containing sample information
          e.g. `[ id:'genome' ]`
    - fasta:
        type: file
        description: Reference genome FASTA file
        pattern: "*.{fa,fasta,fa.gz,fasta.gz}"
  - - meta2:
        type: map
        description: |
          Groovy Map containing annotation information
          e.g. `[ id:'annotation' ]`
    - gtf:
        type: file
        description: Gene annotation GTF file
        pattern: "*.{gtf,gtf.gz}"

output:
  - index:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'genome' ]`
      - "star":
          type: directory
          description: STAR genome index directory
          pattern: "star"
  - versions:
      - "versions.yml":
          type: file
          description: File containing software versions
          pattern: "versions.yml"

authors:
  - "@Franzx7"
maintainers:
  - "@Franzx7"

modules/local/star/fusion/main.nf
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

    # Copy outputs to expected locations
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


modules/local/star/fusion/environment.yml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/nf-core/modules/master/modules/environment-schema.json
channels:
  - conda-forge
  - bioconda
dependencies:
  - "bioconda::star-fusion=1.12.0"

modules/local/star/fusion/meta.yml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/nf-core/modules/master/modules/meta-schema.json
name: "star_fusion"
description: "Detect fusion transcripts using STAR-Fusion"
keywords:
  - fusion
  - transcripts
  - star-fusion
  - rna-seq
  - oncology
tools:
  - "star-fusion":
      description: "STAR-Fusion uses the STAR aligner to identify candidate fusion transcripts"
      homepage: "https://github.com/STAR-Fusion/STAR-Fusion"
      documentation: "https://github.com/STAR-Fusion/STAR-Fusion/wiki"
      tool_dev_url: "https://github.com/STAR-Fusion/STAR-Fusion"
      doi: "10.1186/s13059-019-1842-9"
      licence: ["BSD-3-Clause"]
      identifier: biotools:star-fusion

input:
  - - meta:
        type: map
        description: |
          Groovy Map containing sample information
          e.g. `[ id:'sample1', single_end:false ]`
    - chimeric_junctions:
        type: file
        description: Chimeric junction file from STAR alignment
        pattern: "*.Chimeric.out.junction"
    - bam:
        type: file
        description: BAM file from STAR alignment
        pattern: "*.bam"
  - - meta2:
        type: map
        description: |
          Groovy Map containing reference information
          e.g. `[ id:'ctat_genome_lib' ]`
    - ctat_genome_lib:
        type: directory
        description: CTAT genome library directory
        pattern: "*"

output:
  - predictions:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'sample1', single_end:false ]`
      - "*.star-fusion.fusion_predictions.tsv":
          type: file
          description: STAR-Fusion predictions file
          pattern: "*.star-fusion.fusion_predictions.tsv"
  - predictions_abridged:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'sample1', single_end:false ]`
      - "*.star-fusion.fusion_predictions.abridged.tsv":
          type: file
          description: STAR-Fusion abridged predictions file
          pattern: "*.star-fusion.fusion_predictions.abridged.tsv"
  - outdir:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'sample1', single_end:false ]`
      - "*_star_fusion_outdir":
          type: directory
          description: STAR-Fusion output directory
          pattern: "*_star_fusion_outdir"
  - versions:
      - "versions.yml":
          type: file
          description: File containing software versions
          pattern: "versions.yml"

authors:
  - "@Franzx7"
maintainers:
  - "@Franzx7"

modules/local/fusioninspector/main.nf
process FUSION_INSPECTOR {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "community.wave.seqera.io/library/fusioninspector:2.8.0--hdfd78af_0"

    input:
    tuple val(meta), path(fusion_predictions), path(bam)
    tuple val(meta2), path(ctat_genome_lib)

    output:
    tuple val(meta), path("${prefix}_fusion_inspector_outdir"), emit: outdir
    tuple val(meta), path("${prefix}.FusionInspector.fusions.tsv"), emit: fusions
    tuple val(meta), path("${prefix}.FusionInspector.fusions.abridged.tsv"), emit: fusions_abridged
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    FusionInspector \\
        --fusions ${fusion_predictions} \\
        --genome_lib ${ctat_genome_lib} \\
        --left_fq ${bam} \\
        --output_dir ${prefix}_fusion_inspector_outdir \\
        --CPU ${task.cpus} \\
        ${args}

    # Copy outputs to expected locations
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


modules/local/fusioninspector/environment.yml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/nf-core/modules/master/modules/environment-schema.json
channels:
  - conda-forge
  - bioconda
dependencies:
  - "bioconda::fusioninspector=2.8.0"

modules/local/fusioninspector/meta.yml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/nf-core/modules/master/modules/meta-schema.json
name: "fusioninspector"
description: "Validate and inspect fusion predictions"
keywords:
  - fusion
  - validation
  - inspector
  - rna-seq
  - oncology
tools:
  - "fusioninspector":
      description: "FusionInspector assists in fusion transcript discovery"
      homepage: "https://github.com/FusionInspector/FusionInspector"
      documentation: "https://github.com/FusionInspector/FusionInspector/wiki"
      tool_dev_url: "https://github.com/FusionInspector/FusionInspector"
      doi: "10.1186/s13059-019-1842-9"
      licence: ["BSD-3-Clause"]
      identifier: biotools:fusioninspector

input:
  - - meta:
        type: map
        description: |
          Groovy Map containing sample information
          e.g. `[ id:'sample1', single_end:false ]`
    - fusion_predictions:
        type: file
        description: Fusion predictions file from STAR-Fusion
        pattern: "*.tsv"
    - bam:
        type: file
        description: BAM file from STAR alignment
        pattern: "*.bam"
  - - meta2:
        type: map
        description: |
          Groovy Map containing reference information
          e.g. `[ id:'ctat_genome_lib' ]`
    - ctat_genome_lib:
        type: directory
        description: CTAT genome library directory
        pattern: "*"

output:
  - outdir:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'sample1', single_end:false ]`
      - "*_fusion_inspector_outdir":
          type: directory
          description: FusionInspector output directory
          pattern: "*_fusion_inspector_outdir"
  - fusions:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'sample1', single_end:false ]`
      - "*.FusionInspector.fusions.tsv":
          type: file
          description: FusionInspector validated fusions file
          pattern: "*.FusionInspector.fusions.tsv"
  - fusions_abridged:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'sample1', single_end:false ]`
      - "*.FusionInspector.fusions.abridged.tsv":
          type: file
          description: FusionInspector abridged fusions file
          pattern: "*.FusionInspector.fusions.abridged.tsv"
  - versions:
      - "versions.yml":
          type: file
          description: File containing software versions
          pattern: "versions.yml"

authors:
  - "@Franzx7"
maintainers:
  - "@Franzx7"

modules/local/fastqc/main.nf
process FASTQC {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "community.wave.seqera.io/library/fastqc:0.12.1--hdfd78af_0"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip") , emit: zip
    path  "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    if (meta.single_end) {
        """
        fastqc $args --threads $task.cpus $reads

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastqc: \$( fastqc --version | sed '/FastQC v/!d; s/.*v//' )
        END_VERSIONS
        """
    } else {
        """
        fastqc $args --threads $task.cpus $reads

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastqc: \$( fastqc --version | sed '/FastQC v/!d; s/.*v//' )
        END_VERSIONS
        """
    }

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_fastqc.html
    touch ${prefix}_fastqc.zip

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$( fastqc --version | sed '/FastQC v/!d; s/.*v//' )
    END_VERSIONS
    """
}


modules/local/fastqc/environment.yml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/nf-core/modules/master/modules/environment-schema.json
channels:
  - conda-forge
  - bioconda
dependencies:
  - "bioconda::fastqc=0.12.1"

modules/local/fastqc/meta.yml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/nf-core/modules/master/modules/meta-schema.json
name: "fastqc"
description: "Run FastQC on sequenced reads"
keywords:
  - quality control
  - qc
  - adapters
  - fastq
tools:
  - "fastqc":
      description: "A quality control tool for high throughput sequence data"
      homepage: "https://www.bioinformatics.babraham.ac.uk/projects/fastqc/"
      documentation: "https://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/"
      tool_dev_url: "https://github.com/s-andrews/FastQC"
      licence: ["GPL v3"]
      identifier: biotools:fastqc

input:
  - - meta:
        type: map
        description: |
          Groovy Map containing sample information
          e.g. `[ id:'sample1', single_end:false ]`
    - reads:
        type: file
        description: |
          List of input FastQ files of size 1 and 2 for single-end and paired-end data,
          respectively.
        pattern: "*.{fq,fastq,fq.gz,fastq.gz}"

output:
  - html:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'sample1', single_end:false ]`
      - "*.html":
          type: file
          description: FastQC report
          pattern: "*_fastqc.html"
  - zip:
      - meta:
          type: map
          description: |
            Groovy Map containing sample information
            e.g. `[ id:'sample1', single_end:false ]`
      - "*.zip":
          type: file
          description: Fast