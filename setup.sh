#!/bin/bash

# STAR-Fusion Pipeline Setup Script
# This script helps set up the directory structure and download reference data

set -e

echo "=========================================="
echo "STAR-Fusion Pipeline Setup"
echo "=========================================="

# Create directory structure
echo "Creating directory structure..."
mkdir -p data/fastqs
mkdir -p references
mkdir -p results
mkdir -p logs

echo " Directories created"

# Create example samplesheet
echo ""
echo "Creating example samplesheet..."
if [ ! -f "samplesheet.csv" ]; then
 cp samplesheet.example.csv samplesheet.csv
 echo " samplesheet.csv created (update with your sample paths)"
else
 echo " samplesheet.csv already exists, skipping"
fi

# Create example params file
echo ""
echo "Creating example params file..."
if [ ! -f "params.json" ]; then
 cp params.example.json params.json
 echo " params.json created (update with your settings)"
else
 echo " params.json already exists, skipping"
fi

# Show setup summary
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Place your FASTQ files in: data/fastqs/"
echo " Or update samplesheet.csv with full paths to your FASTQ files"
echo ""
echo "2. Download CTAT Genome Library:"
echo " cd references"
echo " wget http://ctat.github.io/CTAT_LR/CTAT_LR_v37.tar.gz"
echo " tar -xzf CTAT_LR_v37.tar.gz"
echo " cd .."
echo ""
echo "3. Update params.json with your settings"
echo ""
echo "4. Run the pipeline:"
echo " nextflow run workflows/main.nf -profile docker -params-file params.json"
echo ""
echo "For help, see README.md or run:"
echo " nextflow run workflows/main.nf --help"
echo ""
