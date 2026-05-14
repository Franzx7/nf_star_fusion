# Quick Start Guide

## Installation (First Time Only)

### 1. Install Nextflow
```bash
curl -s https://get.nextflow.io | bash
chmod +x nextflow
export PATH=$PATH:$(pwd)
```

### 2. Install Docker or Singularity
Choose one:

**Docker:**
```bash
# Ubuntu/Debian
sudo apt-get install docker.io docker-compose

# MacOS
brew install docker
```

**Singularity:**
```bash
# Ubuntu/Debian
sudo apt-get install singularity-container
```

### 3. Run Setup Script
```bash
cd nf_star_fusion
bash setup.sh
```

---

## Preparing Your Data

### Option A: Using Directory with Auto-Discovery
Place paired-end FASTQ files in `data/fastqs/`:
```
data/fastqs/
 sample1_R1.fastq.gz
 sample1_R2.fastq.gz
 sample2_R1.fastq.gz
 sample2_R2.fastq.gz
```

### Option B: Using Samplesheet (Recommended)
Create `samplesheet.csv`:
```csv
sample_id,read1,read2
sample1,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
sample2,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
```

---

## Getting Reference Data

### Download CTAT Genome Library
```bash
mkdir -p references
cd references

# Download (choose appropriate version for your genome)
wget http://ctat.github.io/CTAT_LR/CTAT_LR_v37.tar.gz

# Extract
tar -xzf CTAT_LR_v37.tar.gz

# Verify structure
ls CTAT_LR_v37/
# Should contain: ctat_genome_lib_* subdirectory

cd ..
```

---

## Running the Pipeline

### Basic Run (Local Docker)
```bash
nextflow run . -profile docker \
 --input_fastq_dir ./data/fastqs \
 --ctat_genome_lib_dir ./references/CTAT_LR_v37 \
 --outdir ./results
```

Or explicitly:
```bash
nextflow run main.nf -profile docker \
 --input_fastq_dir ./data/fastqs \
 --ctat_genome_lib_dir ./references/CTAT_LR_v37
```

### With Samplesheet
```bash
nextflow run . -profile docker \
 --samplesheet samplesheet.csv \
 --ctat_genome_lib_dir ./references/CTAT_LR_v37
```

### With Custom Parameters
```bash
nextflow run . -profile docker \
 --input_fastq_dir ./data/fastqs \
 --ctat_genome_lib_dir ./references/CTAT_LR_v37 \
 --min_junction_reads 2 \
 --skip_multiqc
```

### On HPC (SLURM)
```bash
nextflow run . -profile slurm,docker \
 --input_fastq_dir ./data/fastqs \
 --ctat_genome_lib_dir ./references/CTAT_LR_v37 \
 -with-report reports/report.html
```

### Resume Failed Runs
```bash
nextflow run . -resume -profile docker \
 --input_fastq_dir ./data/fastqs \
 --ctat_genome_lib_dir ./references/CTAT_LR_v37
```

---

## Monitoring Execution

### Real-time Monitoring
```bash
# In another terminal, watch the log
tail -f .nextflow.log
```

### After Completion
Check these files:
- **HTML Report**: `results/execution_report.html` - Task execution timeline
- **DAG Diagram**: `results/pipeline_dag.html` - Pipeline structure visualization
- **Trace**: `results/execution_trace.txt` - Detailed task statistics

---

## Viewing Results

### Fusion Predictions
```bash
# STAR-Fusion predictions
head results/star_fusion/*.tsv

# FusionInspector validated results
head results/fusion_inspector/*.final
```

### Quality Reports
```bash
# Open in browser
open results/multiqc/multiqc_report.html

# Or on Linux
firefox results/multiqc/multiqc_report.html
```

---

## Troubleshooting

### "Docker daemon not running"
```bash
# Start Docker
sudo systemctl start docker
# Or on Mac
open /Applications/Docker.app
```

### "No FASTQ files found"
```bash
# Verify files exist and are gzipped
ls -lah data/fastqs/
file data/fastqs/*.fastq.gz
```

### "Out of memory"
Edit `conf/base.config` and increase memory for STAR_ALIGN:
```nextflow
withName: 'STAR_ALIGN' {
 cpus = 16
 memory = '64 GB'
}
```

### "Nextflow command not found"
```bash
# Add to PATH
export PATH=$PATH:$HOME/nextflow
# Or install globally
sudo mv nextflow /usr/local/bin/
```

---

## Performance Tips

1. **Use local SSD storage** for best speed:
 ```bash
 nextflow run workflows/main.nf -work-dir /tmp/nf_work ...
 ```

2. **Run multiple samples in parallel** (automatic):
 ```bash
 nextflow run workflows/main.nf -qs 4 ... # Run 4 samples simultaneously
 ```

3. **Profile your runs**:
 ```bash
 nextflow run workflows/main.nf -with-trace trace.txt -with-timeline timeline.html ...
 ```

---

## Advanced Usage

### Custom Configuration
Create `my_config.nf`:
```nextflow
process {
 executor = 'slurm'
 queue = 'gpu'
 time = '24h'
}
```

Run with:
```bash
nextflow run workflows/main.nf -c my_config.nf ...
```

### Building Custom Docker Image
```bash
docker build -t my-star-fusion:1.0 .
```

Edit `nextflow.config` and change:
```nextflow
process.container = 'my-star-fusion:1.0'
```

---

## Getting Help

```bash
# Show all options
nextflow run workflows/main.nf --help

# Show workflow DAG before running
nextflow run workflows/main.nf -preview

# Check Nextflow version
nextflow -version

# View documentation
cat README.md
```

---

## Sample Analysis Times

Approximate run times (paired-end RNA-seq, 200M reads):

| Step | Time | Memory |
|------|------|--------|
| STAR Alignment | 30-60 min | 30 GB |
| STAR-Fusion | 10-20 min | 8 GB |
| FusionInspector | 15-30 min | 16 GB |
| **Total per sample** | **~1-2 hours** | **Peak: 30 GB** |

---

## Need Help?

1. **Check logs**: `.nextflow.log`
2. **Read documentation**: `README.md`
3. **Tool documentation**: 
 - [Nextflow Docs](https://docs.seqera.io/nextflow/)
 - [STAR-Fusion Wiki](https://github.com/STAR-Fusion/STAR-Fusion-Tutorial/wiki)
4. **Community**: [Nextflow Gitter](https://gitter.im/nextflow-io/nextflow)
