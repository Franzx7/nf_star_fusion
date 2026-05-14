# STAR-Fusion Nextflow Pipeline - Complete Implementation

## What's Been Created

A **production-ready Nextflow pipeline** for detecting RNA-seq fusion transcripts using STAR-Fusion and FusionInspector.

---

## Complete File Structure

```
nf_star_fusion/
 nextflow.config ← Main pipeline configuration
 conf/
 base.config ← Resource allocation & process config
 modules/ ← Reusable process modules
 star_index.nf ← STAR genome indexing
 star_align.nf ← RNA-seq alignment
 star_fusion.nf ← Fusion detection
 fusion_inspector.nf ← Fusion validation
 qc.nf ← Quality control (FastQC/MultiQC)
 workflows/
 main.nf ← Main workflow orchestration
 README.md ← Full documentation
 QUICKSTART.md ← Quick start guide (START HERE!)
 samplesheet.example.csv ← Example sample metadata
 params.example.json ← Example parameters
 Dockerfile ← Docker image definition
 setup.sh ← Initial setup script
 .gitignore ← Git ignore patterns
```

---

## Pipeline Workflow

```
INPUT FASTQ FILES
 ↓
[Optional] STAR INDEX (if custom genome)
 ↓
FASTQC (Quality Control)
 ↓
STAR ALIGNMENT (RNA-seq alignment with chimeric junction detection)
 ↓
STAR-FUSION (Fusion transcript detection)
 ↓
FUSION INSPECTOR (Validation and refinement)
 ↓
MULTIQC (Aggregate QC reports)
 ↓
RESULTS (Annotated fusion predictions)
```

---

## Quick Start (3 Steps)

### 1⃣ **Setup**
```bash
cd nf_star_fusion
bash setup.sh
```

### 2⃣ **Get Your Data**
```bash
# Add your FASTQ files
cp /path/to/your/*.fastq.gz data/fastqs/

# Download reference genome
cd references
wget http://ctat.github.io/CTAT_LR/CTAT_LR_v37.tar.gz
tar -xzf CTAT_LR_v37.tar.gz
cd ..
```

### 3⃣ **Run Pipeline**
```bash
nextflow run workflows/main.nf \
 -profile docker \
 --input_fastq_dir ./data/fastqs \
 --ctat_genome_lib_dir ./references/CTAT_LR_v37 \
 --outdir ./results
```

---

## Key Features

 **Fully Modular** - Each process is independent and reusable
 **Multi-Platform** - Runs on local machine, HPC (SLURM/SGE), cloud
 **Containerized** - Docker & Singularity support for reproducibility
 **Well-Documented** - Comprehensive README + quick start guide
 **Scalable** - Handles single sample or batch processing
 **Fault-Tolerant** - Resume capability for interrupted runs
 **Observable** - Execution reports, DAG visualization, trace files

---

## Input/Output

### Inputs
- **FASTQ files** (paired-end, gzip compressed)
- **Reference genome** (or use CTAT pre-built library)
- **Gene annotations** (GTF format, included in CTAT)

### Outputs
| File | Description |
|------|-------------|
| `*.star-fusion.fusion_predictions.tsv` | Full STAR-Fusion predictions |
| `*.star-fusion.fusion_predictions.abridged.tsv` | Simplified predictions |
| `*.finspector.fusion_predictions.final` | Validated high-confidence fusions |
| `multiqc_report.html` | QC metrics aggregation |
| `execution_report.html` | Pipeline execution timeline |

---

## Available Parameters

```bash
# Required
--input_fastq_dir ./data/fastqs
--ctat_genome_lib_dir ./references/CTAT_LR

# Optional
--skip_fastqc false # Skip quality control
--skip_multiqc false # Skip report aggregation
--min_junction_reads 1 # Fusion call threshold
--min_spanning_frags 0 # Fragment threshold
--star_threads 8 # CPU cores for STAR
--outdir ./results # Output directory
```

---

## Execution Profiles

Run with `-profile` flag:

```bash
-profile docker # Local with Docker
-profile singularity # Local with Singularity
-profile slurm # HPC with SLURM scheduler
-profile sge # HPC with Sun Grid Engine
-profile local # Local execution (no containers)
```

Combine profiles:
```bash
-profile slurm,docker # SLURM scheduler + Docker containers
```

---

## Documentation Files

| File | Purpose |
|------|---------|
| **README.md** | Complete documentation, parameters, troubleshooting |
| **QUICKSTART.md** | Step-by-step setup and first run |
| **nextflow.config** | Global configuration, execution profiles |
| **conf/base.config** | Resource allocation per process |
| **modules/*.nf** | Individual process implementations |
| **workflows/main.nf** | Pipeline orchestration and logic |

---

## System Requirements

### Minimum
- 8 CPU cores
- 32 GB RAM
- 200 GB disk space

### Recommended
- 16+ CPU cores
- 64 GB RAM
- 500 GB+ disk space (for reference data + results)

### Software
- **Nextflow** >= 21.10.0
- **Docker** or **Singularity**
- Java 8+

---

## Building Docker Image (Optional)

```bash
# Build from provided Dockerfile
docker build -t star-fusion:latest .

# Push to registry
docker tag star-fusion:latest your-registry/star-fusion:latest
docker push your-registry/star-fusion:latest
```

---

## Workflow Details

### STAR_INDEX
- **Input**: Genome FASTA + GTF annotation
- **Output**: STAR genome index
- **Note**: Optional if using CTAT pre-built library

### STAR_ALIGN
- **Input**: Paired-end FASTQ files + STAR index
- **Output**: Aligned BAM file + chimeric junctions
- **Parameters**: 8 CPU cores, 30 GB RAM

### STAR_FUSION
- **Input**: Chimeric junctions + BAM file
- **Output**: Fusion predictions (TSV)
- **Thresholds**: `--min_junction_reads`, `--min_spanning_frags`

### FUSION_INSPECTOR
- **Input**: STAR-Fusion predictions + BAM
- **Output**: Validated fusion predictions
- **Purpose**: Refine and validate fusion calls

### FASTQC & MULTIQC
- **Input**: FASTQ files + alignment logs
- **Output**: HTML quality reports
- **Purpose**: QC metrics visualization

---

## Example Commands

### Single Sample, Local Docker
```bash
nextflow run workflows/main.nf -profile docker \
 --samplesheet samplesheet.csv \
 --ctat_genome_lib_dir ./references/CTAT_LR_v37
```

### Batch Processing with SLURM
```bash
nextflow run workflows/main.nf -profile slurm,docker \
 --input_fastq_dir /bulk/fastqs \
 --ctat_genome_lib_dir /shared/CTAT_LR_v37 \
 --outdir /results/fusion_analysis \
 -N your-email@institution.edu
```

### Resume Failed Run
```bash
nextflow run workflows/main.nf -resume -profile docker \
 --samplesheet samplesheet.csv \
 --ctat_genome_lib_dir ./references/CTAT_LR_v37
```

### Dry Run (Preview without execution)
```bash
nextflow run workflows/main.nf -preview -profile docker \
 --samplesheet samplesheet.csv \
 --ctat_genome_lib_dir ./references/CTAT_LR_v37
```

---

## Monitoring & Results

### During Execution
```bash
# Watch logs in real-time
tail -f .nextflow.log

# Check process status
ps aux | grep nextflow
```

### After Completion
```bash
# Open execution report in browser
open results/execution_report.html

# View pipeline DAG
open results/pipeline_dag.html

# Check QC report
open results/multiqc/multiqc_report.html

# View fusion predictions
head results/fusion_inspector/*.final
```

---

## Troubleshooting Quick Links

See **QUICKSTART.md** or **README.md** for:
- Docker daemon issues
- Out of memory errors
- File path problems
- Job submission on HPC
- Performance optimization

---

## Support Resources

- **Nextflow**: https://docs.seqera.io/nextflow/
- **STAR-Fusion**: https://github.com/STAR-Fusion/STAR-Fusion-Tutorial/wiki
- **FusionInspector**: https://github.com/FusionInspector/FusionInspector/wiki
- **Nextflow Community**: https://gitter.im/nextflow-io/nextflow

---

## Next Steps

1. **Read**: Start with `QUICKSTART.md`
2. **Setup**: Run `bash setup.sh`
3. **Prepare**: Add your FASTQ files to `data/fastqs/`
4. **Download**: Get CTAT reference library
5. **Run**: Execute the pipeline
6. **Analyze**: Check results in `results/`

---

## Learning Path

**Beginner** → QUICKSTART.md
**Intermediate** → README.md + individual module comments
**Advanced** → nextflow.config + conf/base.config + tool documentation

---

## Pipeline Status

| Component | Status | Version |
|-----------|--------|---------|
| Main workflow | Complete | 1.0.0 |
| STAR indexing | Complete | 2.7.10b |
| STAR alignment | Complete | 2.7.10b |
| STAR-Fusion | Complete | 1.10.1 |
| FusionInspector | Complete | 2.5.0 |
| QC modules | Complete | FastQC 0.11.9, MultiQC 1.14 |
| Docker support | Complete | - |
| HPC support | Complete | SLURM/SGE |

---

## Ready to Go!

Your Nextflow STAR-Fusion pipeline is **production-ready**. Start with the QUICKSTART guide and you'll be running fusion analysis in minutes!

For detailed help: `nextflow run workflows/main.nf --help`
