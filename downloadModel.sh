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

# Check if gdown is installed
if ! command -v gdown &> /dev/null; then
    echo "gdown not found. Installing..."
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
    echo "[$COUNT/$TOTAL] Downloading: $url"
    
    # Download to current directory
    if gdown --fuzzy "$url" -O "$CURRENT_DIR/"; then
        echo "✓ Successfully downloaded"
    else
        echo "✗ Failed to download: $url"
    fi
    echo "--------------------------------"
    
done < "$URL_FILE"

echo "================================="
echo "Download complete!"
echo "Files saved in: $CURRENT_DIR"