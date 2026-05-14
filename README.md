# STAR-Fusion Nextflow Pipeline

A comprehensive Nextflow pipeline for detecting fusion transcripts from RNA-seq data using STAR-Fusion and FusionInspector.

## Overview

This pipeline performs the following analysis steps:

1. **Quality Control**: FastQC analysis of input reads
2. **Genome Indexing**: Generate STAR index (optional, can use pre-built CTAT library)
3. **Alignment**: Align RNA-seq reads to reference genome with STAR
4. **Fusion Detection**: Identify fusion transcripts using STAR-Fusion
5. **Validation**: Refine and validate fusion predictions with FusionInspector
6. **Reporting**: MultiQC aggregation of QC metrics

## Prerequisites

### Required Software
- **Nextflow** >= 21.10.0
- **Docker** or **Singularity** (for containerized execution)
- **STAR** (>= 2.7.3a)
- **STAR-Fusion** (>= 1.10.1)
- **FusionInspector** (>= 2.2.0)
- **FastQC** (for quality control)
- **MultiQC** (for report aggregation)

### Reference Data
- **CTAT Genome Library**: Pre-built resource with STAR index, annotations, and databases
 - Download from: http://ctat.github.io/CTAT_LR/

Or provide separately:
- Genome FASTA file
- Gene annotation (GTF/GFF)

## Quick Start

### 1. Prepare Your Data

Organize your FASTQ files:
```
data/fastqs/
 sample1_R1.fastq.gz
 sample1_R2.fastq.gz
 sample2_R1.fastq.gz
 sample2_R2.fastq.gz
...
```

### 2. Download Reference Data

```bash
# Download CTAT Genome Library
mkdir -p references
cd references
wget http://ctat.github.io/CTAT_LR/CTAT_LR_v37.tar.gz
tar -xzf CTAT_LR_v37.tar.gz
cd ..
```

### 3. Run the Pipeline

#### Using Docker (recommended):
```bash
nextflow run workflows/main.nf \
 -profile docker \
 --input_fastq_dir ./data/fastqs \
 --ctat_genome_lib_dir ./references/CTAT_LR \
 --outdir ./results
```

#### Using Singularity:
```bash
nextflow run workflows/main.nf \
 -profile singularity \
 --input_fastq_dir ./data/fastqs \
 --ctat_genome_lib_dir ./references/CTAT_LR \
 --outdir ./results
```

#### On HPC (SLURM):
```bash
nextflow run workflows/main.nf \
 -profile slurm,docker \
 --input_fastq_dir ./data/fastqs \
 --ctat_genome_lib_dir ./references/CTAT_LR \
 --outdir ./results
```

### 4. View Results

Once complete, check:
- **Fusion predictions**: `results/star_fusion/*.tsv`
- **Validated fusions**: `results/fusion_inspector/*.final`
- **MultiQC report**: `results/multiqc/multiqc_report.html`
- **Pipeline report**: `results/execution_report.html`

## Parameters

### Required Parameters
| Parameter | Description |
|-----------|-------------|
| `--input_fastq_dir` | Directory containing paired-end FASTQ files (gzipped) |
| `--ctat_genome_lib_dir` | Path to CTAT genome library |

### Optional Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| `--samplesheet` | - | CSV with columns: sample_id, read1, read2 (alternative to input_fastq_dir) |
| `--genome_fa` | - | Genome FASTA (only if building custom index) |
| `--gtf_file` | - | Gene annotation GTF (only if building custom index) |
| `--outdir` | ./results | Output directory |
| `--skip_fastqc` | false | Skip FastQC analysis |
| `--skip_multiqc` | false | Skip MultiQC aggregation |
| `--min_junction_reads` | 1 | Minimum junction reads for fusion calls |
| `--min_spanning_frags` | 0 | Minimum spanning fragments |
| `--star_threads` | 8 | Number of STAR alignment threads |
| `--star_memory_gb` | 30 | Memory allocated for STAR (GB) |

## Using a Samplesheet

Create a CSV file with your samples:

```csv
sample_id,read1,read2
sample1,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
sample2,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
```

Then run:
```bash
nextflow run workflows/main.nf \
 -profile docker \
 --samplesheet samples.csv \
 --ctat_genome_lib_dir ./references/CTAT_LR \
 --outdir ./results
```

## Output Structure

```
results/
 star_fusion/
 sample_*.star-fusion.fusion_predictions.*.tsv
 fusion_inspector/
 sample_*.finspector.fusion_predictions.final*
 fastqc/
 sample_*_fastqc.html
 multiqc/
 multiqc_report.html
 multiqc_data/
 execution_timeline.html
 execution_report.html
 execution_trace.txt
 pipeline_dag.html
```

## Key Output Files

- **`*.star-fusion.fusion_predictions.tsv`**: Full STAR-Fusion predictions with all fields
- **`*.star-fusion.fusion_predictions.abridged.tsv`**: Simplified fusion predictions
- **`*.finspector.fusion_predictions.final`**: FusionInspector validated predictions (highest confidence)

## Advanced Configuration

### Custom Resource Allocation

Edit `conf/base.config` to adjust CPU/memory for different processes:

```nextflow
withName: 'STAR_ALIGN' {
 cpus = 16
 memory = '64 GB'
 time = '8h'
}
```

### Custom Profiles

Add a custom profile in `nextflow.config`:

```nextflow
profiles {
 custom_hpc {
 executor.name = 'slurm'
 executor.queueSize = 20
 queue = 'gpu'
 time = '24h'
 }
}
```

Then run:
```bash
nextflow run workflows/main.nf -profile custom_hpc ...
```

## Troubleshooting

### Out of Memory Errors
- Increase `--star_memory_gb` or allocate more memory in `conf/base.config`

### Docker Issues
- Ensure Docker is running: `docker ps`
- Rebuild image if needed: `docker build -t star-fusion:latest .`

### No Fusions Found
- Check alignment quality in FastQC reports
- Adjust `--min_junction_reads` and `--min_spanning_frags` thresholds
- Verify CTAT genome library is correct

### Pipeline Won't Start
- Check all required parameters are provided
- Verify file paths are correct
- Run with `--help` to see all options

## Performance Tips

1. **Use fast local storage** for work directory: `--work /tmp/work`
2. **Reduce retry attempts** for stable HPC: edit `conf/base.config`
3. **Parallelize with multiple samples**: Pipeline processes samples independently
4. **Monitor execution**: Check `execution_report.html` for bottlenecks

## Citation

If you use this pipeline, please cite:

- **STAR**: Dobin et al. Bioinformatics. 2013
- **STAR-Fusion**: Haas et al. Nature Biotechnology. 2019
- **FusionInspector**: Haas et al. Nucleic Acids Research. 2019
- **Nextflow**: Di Tommaso et al. Nature Biotechnology. 2017

## Documentation

- [Nextflow Documentation](https://docs.seqera.io/nextflow/)
- [STAR Manual](https://github.com/alexdobin/STAR/blob/master/doc/STARmanual.pdf)
- [STAR-Fusion Wiki](https://github.com/STAR-Fusion/STAR-Fusion-Tutorial/wiki)
- [FusionInspector Wiki](https://github.com/FusionInspector/FusionInspector/wiki)

## Support

For issues or questions:
1. Check the logs: `cat .nextflow.log`
2. Review output files in `results/`
3. Consult tool documentation (links above)
4. Check [Nextflow community forum](https://gitter.im/nextflow-io/nextflow)

## License

[Your License Here]

## Authors

Your Name and Contributors
