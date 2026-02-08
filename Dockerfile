# Base Image (CUDA & Python ready)
FROM runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu22.04

# 1. Install System Dependencies
# 'git' is crucial here for the start script to work
RUN apt-get update && apt-get install -y \
    libfuse2 \
    wget \
    git \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

# 2. Setup ImageMagick 7 (Extracted & Ready)
WORKDIR /opt
RUN wget https://imagemagick.org/archive/binaries/magick && \
    chmod +x magick && \
    ./magick --appimage-extract && \
    rm magick

# 3. Pre-install Python Dependencies
# We only install the MISSING tools.
# PyTorch is already baked into the base image.
RUN pip install --no-cache-dir \
    Wand \
    PyWavelets \
    comfy-cli

# 4. Add the Start Script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 5. Set the Entrypoint
# This tells RunPod: "When you wake up, run this script immediately"
CMD ["/start.sh"]
