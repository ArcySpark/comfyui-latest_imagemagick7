#!/bin/bash

# --- 1. Environment Setup ---
export MAGICK_HOME="/opt/squashfs-root/usr"
export LD_LIBRARY_PATH="/opt/squashfs-root/usr/lib:$LD_LIBRARY_PATH"
export PATH="/opt/squashfs-root/usr/bin:$PATH"

# --- 2. ComfyUI Core Setup ---
if [ ! -d "/workspace/ComfyUI" ]; then
    echo "Downloading ComfyUI..."
    cd /workspace
    git clone https://github.com/comfyanonymous/ComfyUI.git
    cd ComfyUI
    pip install -r requirements.txt
else
    echo "Updating ComfyUI..."
    cd /workspace/ComfyUI
    git pull
    pip install -r requirements.txt
fi

# --- 3. Install Managers (The "Baked In" Part) ---
CD_CUSTOM="/workspace/ComfyUI/custom_nodes"
mkdir -p $CD_CUSTOM

# A. ComfyUI Manager
if [ ! -d "$CD_CUSTOM/ComfyUI-Manager" ]; then
    echo "Installing ComfyUI Manager..."
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git $CD_CUSTOM/ComfyUI-Manager
else
    cd $CD_CUSTOM/ComfyUI-Manager && git pull
fi

# B. Civitai Helper
if [ ! -d "$CD_CUSTOM/ComfyUI-Civitai-Helper" ]; then
    echo "Installing Civitai Helper..."
    git clone https://github.com/zixaphir/ComfyUI-Civitai-Helper.git $CD_CUSTOM/ComfyUI-Civitai-Helper
else
    cd $CD_CUSTOM/ComfyUI-Civitai-Helper && git pull
fi

# --- 4. Inject Civitai API Key ---
# This python snippet creates the config file the node expects, using the ENV VAR
if [ -n "$CIVITAI_API_KEY" ]; then
    echo "Injecting Civitai API Key..."
    python3 -c "
import json
import os

# Path to the helper's config file
config_path = '/workspace/ComfyUI/custom_nodes/ComfyUI-Civitai-Helper/config.json'

# Create default config structure if file doesn't exist
data = {}
if os.path.exists(config_path):
    try:
        with open(config_path, 'r') as f:
            data = json.load(f)
    except:
        pass

# Inject the key
data['civitai_api_key'] = os.environ['CIVITAI_API_KEY']

# Write it back
with open(config_path, 'w') as f:
    json.dump(data, f, indent=4)
"
fi

# --- 5. Install Dependencies & Launch ---
echo "Installing dependencies..."
pip install Wand PyWavelets

# --- File Browser Setup ---
if ! command -v filebrowser &> /dev/null; then
    echo "Installing File Browser..."
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
fi

# Setup File Browser Database if it doesn't exist
FB_DB="/workspace/filebrowser.db"
if [ ! -f "$FB_DB" ]; then
    echo "Initializing File Browser database..."
    filebrowser config init -d "$FB_DB"
    filebrowser config set -d "$FB_DB" --address 0.0.0.0 --port 8080 --root /workspace
    # Set default login to admin / admin (Change this in the UI later!)
    filebrowser users add admin admin --perm.admin -d "$FB_DB"
fi

# Start File Browser in the background
echo "Starting File Browser on port 8080..."
filebrowser -d "$FB_DB" -p 8080 -a 0.0.0.0 &

echo "Starting ComfyUI..."
cd /workspace/ComfyUI
python main.py --listen --port 8188
