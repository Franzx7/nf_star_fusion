#!/bin/bash

# Pipeline Validation Script
# Checks that all necessary files are in place and syntactically correct

set -e

echo "=========================================="
echo "STAR-Fusion Pipeline Validation"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

errors=0

# Function to check file exists
check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
    echo -e "${GREEN}${NC} $description"
    return 0
    else
    echo -e "${RED}${NC} $description - FILE NOT FOUND"
    errors=$((errors + 1))
    return 1
    fi
}

# Function to check directory exists
check_dir() {
    local dir=$1
    local description=$2
    
    if [ -d "$dir" ]; then
    echo -e "${GREEN}${NC} $description"
    return 0
    else
    echo -e "${RED}${NC} $description - DIRECTORY NOT FOUND"
    errors=$((errors + 1))
    return 1
    fi
}

echo "Checking Core Configuration Files..."
check_file "nextflow.config" "Main nextflow.config"
check_file "conf/base.config" "Base resource configuration"
echo ""

echo "Checking Workflow Files..."
check_file "workflows/main.nf" "Main workflow"
echo ""

echo "Checking Process Modules..."
check_file "modules/star_index.nf" "STAR index module"
check_file "modules/star_align.nf" "STAR alignment module"
check_file "modules/star_fusion.nf" "STAR-Fusion module"
check_file "modules/fusion_inspector.nf" "FusionInspector module"
check_file "modules/qc.nf" "QC module"
echo ""

echo "Checking Documentation..."
check_file "README.md" "Main README"
check_file "QUICKSTART.md" "Quick start guide"
check_file "IMPLEMENTATION_SUMMARY.md" "Implementation summary"
echo ""

echo "Checking Configuration Examples..."
check_file "params.example.json" "Example parameters"
check_file "samplesheet.example.csv" "Example samplesheet"
echo ""

echo "Checking Supporting Files..."
check_file "Dockerfile" "Docker configuration"
check_file "setup.sh" "Setup script"
check_file ".gitignore" "Git ignore file"
echo ""

echo "Checking Directory Structure..."
check_dir "bin" "bin directory"
check_dir "conf" "conf directory"
check_dir "data" "data directory"
check_dir "docs" "docs directory"
check_dir "modules" "modules directory"
check_dir "tests" "tests directory"
check_dir "workflows" "workflows directory"
echo ""

# Validate nextflow.config syntax (basic check)
echo "Validating Nextflow Configuration Syntax..."
if grep -q "manifest\|profiles\|process" nextflow.config; then
    echo -e "${GREEN}${NC} nextflow.config contains expected sections"
else
    echo -e "${RED}${NC} nextflow.config missing expected sections"
    errors=$((errors + 1))
fi

# Check main.nf has workflow definition
echo "Validating Workflow Definition..."
if grep -q "^workflow {" workflows/main.nf; then
    echo -e "${GREEN}${NC} Workflow definition found"
else
    echo -e "${RED}${NC} Workflow definition missing"
    errors=$((errors + 1))
fi

# Check modules have process definitions
echo "Validating Process Definitions..."
for module in modules/*.nf; do
    if grep -q "^process " "$module"; then
    echo -e "${GREEN}${NC} Process found in $(basename $module)"
    else
    echo -e "${RED}${NC} Process definition missing in $(basename $module)"
    errors=$((errors + 1))
    fi
done
echo ""

# Summary
echo "=========================================="
if [ $errors -eq 0 ]; then
    echo -e "${GREEN} Pipeline validation PASSED${NC}"
    echo ""
    echo "Your Nextflow STAR-Fusion pipeline is ready!"
    echo ""
    echo "Next steps:"
    echo " 1. Read QUICKSTART.md"
    echo " 2. Run: bash setup.sh"
    echo " 3. Add your FASTQ files"
    echo " 4. Download CTAT reference library"
    echo " 5. Run: nextflow run workflows/main.nf -profile docker ..."
    echo ""
    exit 0
else
    echo -e "${RED} Pipeline validation FAILED${NC}"
    echo "Errors found: $errors"
    echo "Please check the files listed above"
    exit 1
fi
