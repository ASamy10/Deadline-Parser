#!/bin/bash

URL_FILE="Model link.txt"  

# Get current directory path
CURRENT_DIR="$(pwd)"

# Check if url file exists
if [ ! -f "$URL_FILE" ]; then
    echo "Error: $URL_FILE not found in current directory!"
    echo "Create $URL_FILE with one Google Drive URL per line"
    exit 1
fi


# Set up Python virtual environment for gdown
VENV_DIR=".gdown-venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment for gdown..."
    python3 -m venv "$VENV_DIR"
fi

# Activate venv and install gdown if needed
source "$VENV_DIR/bin/activate"
if ! python -m gdown --help &> /dev/null; then
    echo "Installing gdown in venv..."
    pip install --upgrade pip
    pip install gdown
fi

# Count valid URLs
TOTAL=$(grep -vE '^\s*$|^\s*#' "$URL_FILE" | wc -l)
COUNT=0

echo "Found $TOTAL URLs to download"
echo "Download destination: $CURRENT_DIR"
echo "--------------------------------"

# Read each line and download
while IFS= read -r url; do
    # Skip empty lines and comments
    if [[ -z "$url" ]] || [[ "$url" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    COUNT=$((COUNT + 1))
    echo "[$COUNT/$TOTAL] Processing: $url"

    FILENAME="model.safetensors"

    if [ -f "$CURRENT_DIR/$FILENAME" ]; then
        echo "✓ File already exists: $FILENAME. Skipping download."
    else
        echo "Downloading: $url -> $FILENAME"
        if gdown --fuzzy "$url" -O "$CURRENT_DIR/$FILENAME"; then
            echo "✓ Successfully downloaded"
        else
            echo "✗ Failed to download: $url"
        fi
    fi
    echo "--------------------------------"
    
done < "$URL_FILE"

echo "================================="
echo "Download complete!"
echo "Files saved in: $CURRENT_DIR"