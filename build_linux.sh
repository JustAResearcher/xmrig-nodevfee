#!/bin/bash
#
# Build XMRig (0% fee) static Linux binary using Docker
# Run this on any machine with Docker installed.
#
# Usage:
#   chmod +x build_linux.sh
#   ./build_linux.sh
#
# Output: xmrig binary in ./release/
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE_NAME="xmrig-custom-builder"
CONTAINER_NAME="xmrig-custom-build-$$"

echo "=== XMRig Custom Builder (0% dev fee) ==="
echo ""

# Build the Docker image (this compiles everything)
echo "[1/3] Building Docker image (compiling XMRig)..."
docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"

# Extract the binary
echo "[2/3] Extracting binary..."
mkdir -p "$SCRIPT_DIR/release"
docker create --name "$CONTAINER_NAME" "$IMAGE_NAME" /bin/true
docker cp "$CONTAINER_NAME:/xmrig/build/xmrig" "$SCRIPT_DIR/release/xmrig"
docker rm "$CONTAINER_NAME"

# Verify
echo "[3/3] Verifying..."
file "$SCRIPT_DIR/release/xmrig"
ls -lh "$SCRIPT_DIR/release/xmrig"

echo ""
echo "=== Build complete! Binary at: release/xmrig ==="
echo "=== Donate level: 0% ==="
