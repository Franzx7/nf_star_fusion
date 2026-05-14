FROM ubuntu:20.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    wget \
    curl \
    unzip \
    gzip \
    bzip2 \
    ca-certificates \
    perl \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install conda for easier package management
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh && \
    /opt/conda/bin/conda clean -a -y

ENV PATH="/opt/conda/bin:$PATH"

# Install bioinformatics tools via conda
RUN conda install -c bioconda -y \
    star=2.7.10b \
    samtools=1.16 \
    fastqc=0.11.9 \
    multiqc=1.14 \
    && conda clean -a -y

# Install STAR-Fusion and FusionInspector from conda-forge
RUN conda install -c bioconda -y \
    star-fusion=1.10.1 \
    fusioninspector=2.5.0 \
    && conda clean -a -y

# Install Trinity for de novo assembly (optional but recommended)
RUN conda install -c bioconda -y \
    trinity=2.14.0 \
    && conda clean -a -y

# Set working directory
WORKDIR /data

# Verify installations
RUN STAR --version && \
    STAR-Fusion --version && \
    FusionInspector --version && \
    fastqc --version && \
    multiqc --version

# Create label
LABEL maintainer="your-email@example.com" \
      description="STAR-Fusion pipeline container" \
      version="1.0.0"

CMD ["/bin/bash"]
