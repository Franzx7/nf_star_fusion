# STAR-Fusion Pipeline - Complete File Index

## You are here: `/home/users/franzake/Projects/BHowitt_works/nf_star_fusion/`

---

## START HERE

| File | Purpose | Time |
|------|---------|------|
| **QUICKSTART.md** | Step-by-step setup & first run | 5 min read |
| **setup.sh** | Initialize directory structure | Run once |
| **validate.sh** | Verify pipeline installation | 1 min |

---

## DOCUMENTATION

| File | Description |
|------|-------------|
| **README.md** | Complete documentation, parameters, troubleshooting |
| **IMPLEMENTATION_SUMMARY.md** | Architecture overview, component details |
| **INDEX.md** | This file - navigation guide |

---

## CONFIGURATION FILES

| File | Purpose |
|------|---------|
| **nextflow.config** | Main pipeline configuration, execution profiles |
| **conf/base.config** | Resource allocation per process |
| **params.example.json** | Example parameters for pipeline |
| **samplesheet.example.csv** | Example sample metadata format |

---

## PIPELINE CODE

### Main Workflow
- **workflows/main.nf** - Pipeline orchestration & logic

### Process Modules
- **modules/star_index.nf** - Generate STAR genome index
- **modules/star_align.nf** - Align RNA-seq reads with STAR
- **modules/star_fusion.nf** - Detect fusions with STAR-Fusion
- **modules/fusion_inspector.nf** - Validate fusions with FusionInspector
- **modules/qc.nf** - Quality control (FastQC + MultiQC)

---

## CONTAINER & DEPLOYMENT

| File | Purpose |
|------|---------|
| **Dockerfile** | Docker container with all tools pre-installed |
| **.gitignore** | Git ignore patterns |

---

## DIRECTORY STRUCTURE

```
nf_star_fusion/
 workflows/
 main.nf ← Main pipeline
 modules/
 star_index.nf
 star_align.nf
 star_fusion.nf
 fusion_inspector.nf
 qc.nf
 conf/
 base.config ← Resource config
 data/ ← Input data (FASTQ files)
 references/ ← Reference genomes & CTAT library
 results/ ← Output directory (generated)
 bin/ ← Custom scripts (optional)
 tests/ ← Test data (optional)
 docs/ ← Additional documentation
 nextflow.config ← Main config file
 QUICKSTART.md ← Read this first!
 README.md ← Full documentation
 IMPLEMENTATION_SUMMARY.md ← Architecture details
 INDEX.md ← Navigation (you are here)
 params.example.json ← Example parameters
 samplesheet.example.csv ← Example samples
 setup.sh ← Setup script
 validate.sh ← Validation script
 Dockerfile ← Container definition
 .gitignore ← Git ignore patterns
```

---

## QUICK REFERENCE

### Installation & Setup
```bash
cd nf_star_fusion
bash setup.sh
bash validate.sh
```

### Basic Run
```bash
nextflow run workflows/main.nf -profile docker \
 --input_fastq_dir ./data/fastqs \
 --ctat_genome_lib_dir ./references/CTAT_LR_v37 \
 --outdir ./results
```

### With Samplesheet
```bash
nextflow run workflows/main.nf -profile docker \
 --samplesheet samplesheet.csv \
 --ctat_genome_lib_dir ./references/CTAT_LR_v37
```

### On HPC (SLURM)
```bash
nextflow run workflows/main.nf -profile slurm,docker \
 --samplesheet samplesheet.csv \
 --ctat_genome_lib_dir ./references/CTAT_LR_v37
```

### Help & Preview
```bash
nextflow run workflows/main.nf --help
nextflow run workflows/main.nf -preview
```

---

## WORKFLOW PIPELINE

```
Input FASTQ (paired-end)
 ↓
 [Optional] STAR INDEX
 ↓
 FastQC QC Check
 ↓
 STAR Alignment
 ↓
 STAR-Fusion Detection
 ↓
 FusionInspector Validation
 ↓
 MultiQC Report Aggregation
 ↓
 Results (TSV files + HTML reports)
```

---

## INPUT/OUTPUT FILES

### Input
- **data/fastqs/** - Paired-end FASTQ files (gzipped)
- **references/CTAT_LR/** - Pre-built CTAT genome library

### Output
- **results/star_fusion/** - STAR-Fusion predictions (TSV)
- **results/fusion_inspector/** - Validated fusions (final predictions)
- **results/multiqc/** - Quality report (HTML)
- **results/execution_report.html** - Pipeline execution timeline
- **results/pipeline_dag.html** - Workflow diagram

---

## AVAILABLE EXECUTION PROFILES

| Profile | Usage | Example |
|---------|-------|---------|
| docker | Local with Docker | `-profile docker` |
| singularity | Local with Singularity | `-profile singularity` |
| slurm | HPC with SLURM | `-profile slurm,docker` |
| sge | HPC with Grid Engine | `-profile sge,docker` |
| local | No containers | `-profile local` |

---

## DOCUMENTATION READING ORDER

1. **QUICKSTART.md** (5 min) - Get running fast
2. **setup.sh** (1 min) - Create directories
3. **validate.sh** (1 min) - Check installation
4. **README.md** (15 min) - Learn all parameters
5. **IMPLEMENTATION_SUMMARY.md** (10 min) - Understand architecture
6. **modules/*.nf** (20 min) - Study implementation

---

## FILE CHECKLIST

Core:
- [x] nextflow.config - Main configuration
- [x] conf/base.config - Resource defaults
- [x] workflows/main.nf - Pipeline logic

Modules:
- [x] modules/star_index.nf
- [x] modules/star_align.nf
- [x] modules/star_fusion.nf
- [x] modules/fusion_inspector.nf
- [x] modules/qc.nf

Documentation:
- [x] README.md - Complete guide
- [x] QUICKSTART.md - Quick start
- [x] IMPLEMENTATION_SUMMARY.md - Architecture

Configuration:
- [x] params.example.json - Parameters
- [x] samplesheet.example.csv - Sample format

Scripts:
- [x] setup.sh - Initialization
- [x] validate.sh - Validation
- [x] Dockerfile - Container

Other:
- [x] .gitignore - Git patterns
- [x] INDEX.md - Navigation (this file)

---

## NEXT ACTIONS

### For First-Time Users
1. Read **QUICKSTART.md** (5 minutes)
2. Run `bash setup.sh` (creates directories)
3. Run `bash validate.sh` (verifies installation)
4. Download CTAT reference library
5. Add your FASTQ files
6. Run the pipeline

### For Integration
1. Review **README.md** for all parameters
2. Customize **conf/base.config** for your HPC
3. Update **nextflow.config** with your settings
4. Prepare input samplesheet
5. Test with small dataset first

### For Troubleshooting
1. Check **README.md** troubleshooting section
2. Review `.nextflow.log` for errors
3. Run `bash validate.sh` to verify installation
4. Check **IMPLEMENTATION_SUMMARY.md** for architecture

---

## SUPPORT RESOURCES

| Resource | Link |
|----------|------|
| **Nextflow Docs** | https://docs.seqera.io/nextflow/ |
| **STAR-Fusion Wiki** | https://github.com/STAR-Fusion/STAR-Fusion-Tutorial/wiki |
| **FusionInspector Wiki** | https://github.com/FusionInspector/FusionInspector/wiki |
| **Nextflow Community** | https://gitter.im/nextflow-io/nextflow |

---

## YOU'RE ALL SET!

Your Nextflow STAR-Fusion pipeline is complete and ready to use.

**Start here:** `cat QUICKSTART.md`

---

*Generated: 2026-05-14* 
*Pipeline Version: 1.0.0* 
*Status: Production Ready*
