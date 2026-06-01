#!/bin/bash

# Define the core assets directory
ASSETS_DIR="./artifacts/assets"

# Check if directory exists; if not, create it
if [ ! -d "$ASSETS_DIR" ]; then
    echo "Creating missing assets directory..."
    mkdir -p "$ASSETS_DIR"
    echo "Done."
else
    echo "Assets directory already exists. Skipping."
fi

# You can also add logic here to move your player files automatically
# mv asciinema-player.min.js "$ASSETS_DIR/" 2>/dev/null
