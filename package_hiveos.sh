#!/bin/bash
#
# package_hiveos.sh — Build and package XMRig custom miner for HiveOS
#
# This script:
#   1. Builds XMRig via Docker (Linux static binary)
#   2. Packages it with HiveOS integration scripts
#   3. Creates a tar.gz ready for upload to HiveOS
#
# Usage:
#   chmod +x package_hiveos.sh
#   ./package_hiveos.sh
#
# Output: xmrig-custom.tar.gz (upload this to HiveOS)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_NAME="xmrig-custom"
PACKAGE_DIR="$SCRIPT_DIR/$PACKAGE_NAME-package"

echo "=== XMRig Custom HiveOS Packager (0% dev fee) ==="
echo ""

# Step 1: Build the Linux binary
echo "[1/4] Building Linux binary via Docker..."
if ! command -v docker &>/dev/null; then
    echo "ERROR: Docker is required. Install Docker first."
    echo ""
    echo "Alternatively, build on a Linux machine directly:"
    echo "  1. Copy this entire xmrig-custom/ directory to a Linux box"
    echo "  2. cd scripts && chmod +x *.sh && ./build_deps.sh && cd .."
    echo "  3. mkdir build && cd build"
    echo "  4. cmake .. -DCMAKE_BUILD_TYPE=Release -DWITH_OPENCL=OFF -DWITH_CUDA=OFF \\"
    echo "       -DBUILD_STATIC=ON \\"
    echo "       -DUV_INCLUDE_DIR=../scripts/deps/include -DUV_LIBRARY=../scripts/deps/lib/libuv.a \\"
    echo "       -DHWLOC_INCLUDE_DIR=../scripts/deps/include -DHWLOC_LIBRARY=../scripts/deps/lib/libhwloc.a \\"
    echo "       -DOPENSSL_ROOT_DIR=../scripts/deps"
    echo "  5. make -j\$(nproc)"
    echo "  6. strip xmrig"
    echo "  7. Copy the xmrig binary to hiveos/ and re-run this script with --skip-build"
    echo ""

    if [[ "$1" != "--skip-build" ]]; then
        # Check if binary was pre-built
        if [[ ! -f "$SCRIPT_DIR/release/xmrig" ]] && [[ ! -f "$SCRIPT_DIR/hiveos/xmrig" ]]; then
            echo "No pre-built binary found. Exiting."
            exit 1
        fi
    fi
else
    "$SCRIPT_DIR/build_linux.sh"
fi

# Step 2: Assemble package
echo "[2/4] Assembling HiveOS package..."
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy HiveOS integration scripts
cp "$SCRIPT_DIR/hiveos/h-manifest.conf" "$PACKAGE_DIR/"
cp "$SCRIPT_DIR/hiveos/h-config.sh"     "$PACKAGE_DIR/"
cp "$SCRIPT_DIR/hiveos/h-run.sh"        "$PACKAGE_DIR/"
cp "$SCRIPT_DIR/hiveos/h-stats.sh"      "$PACKAGE_DIR/"

# Copy binary (from Docker build or pre-built)
if [[ -f "$SCRIPT_DIR/release/xmrig" ]]; then
    cp "$SCRIPT_DIR/release/xmrig" "$PACKAGE_DIR/"
elif [[ -f "$SCRIPT_DIR/hiveos/xmrig" ]]; then
    cp "$SCRIPT_DIR/hiveos/xmrig" "$PACKAGE_DIR/"
else
    echo "ERROR: No xmrig binary found in release/ or hiveos/"
    exit 1
fi

# Make everything executable
chmod +x "$PACKAGE_DIR/xmrig"
chmod +x "$PACKAGE_DIR/h-config.sh"
chmod +x "$PACKAGE_DIR/h-run.sh"
chmod +x "$PACKAGE_DIR/h-stats.sh"

# Step 3: Create tarball
echo "[3/4] Creating tar.gz..."
cd "$SCRIPT_DIR"
tar -czf "${PACKAGE_NAME}.tar.gz" -C "$PACKAGE_DIR" .

# Step 4: Cleanup
rm -rf "$PACKAGE_DIR"

echo "[4/4] Done!"
echo ""
echo "=== Package created: ${PACKAGE_NAME}.tar.gz ==="
echo ""
echo "=== HiveOS Installation Instructions ==="
echo ""
echo "1. Upload ${PACKAGE_NAME}.tar.gz to your HiveOS rig or a web server"
echo "2. In HiveOS dashboard, go to your rig → Flight Sheets"
echo "3. Create a new Flight Sheet:"
echo "   - Coin: Select your coin (e.g., XMR, RVN, etc.)"
echo "   - Wallet: Select your wallet"
echo "   - Pool: Select your pool"
echo "   - Miner: Select 'Custom'"
echo "   - Setup Miner Config:"
echo "     - Miner name: xmrig-custom"
echo "     - Installation URL: (URL to your tar.gz, or use SCP)"
echo "     - Hash algorithm: (your algorithm, e.g., randomx, kawpow)"
echo "     - Wallet and worker template: %WAL%.%WORKER_NAME%"
echo "     - Pool URL: (your pool stratum URL)"
echo "     - Pass: x"
echo "4. Apply the Flight Sheet"
echo ""
echo "Manual SCP upload:"
echo "  scp ${PACKAGE_NAME}.tar.gz root@<RIG_IP>:/tmp/"
echo "  ssh root@<RIG_IP>"
echo "  mkdir -p /hive/miners/custom/xmrig-custom"
echo "  tar -xzf /tmp/${PACKAGE_NAME}.tar.gz -C /hive/miners/custom/xmrig-custom/"
echo ""
