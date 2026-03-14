#!/bin/bash
#
# build_direct_linux.sh — Build XMRig directly on Ubuntu/Debian (no Docker)
#
# Prerequisites: Ubuntu 18.04+ or Debian 10+
#   sudo apt-get install -y git build-essential cmake automake libtool autoconf wget
#
# Usage:
#   chmod +x build_direct_linux.sh
#   ./build_direct_linux.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== XMRig Direct Linux Build (0% dev fee) ==="
echo ""

# Install build dependencies
echo "[1/4] Checking build dependencies..."
DEPS_NEEDED=""
for pkg in build-essential cmake automake libtool autoconf wget; do
    if ! dpkg -s "$pkg" &>/dev/null 2>&1; then
        DEPS_NEEDED="$DEPS_NEEDED $pkg"
    fi
done

if [[ -n "$DEPS_NEEDED" ]]; then
    echo "Installing missing packages:$DEPS_NEEDED"
    sudo apt-get update
    sudo apt-get install -y $DEPS_NEEDED
fi

# Build dependencies (libuv, hwloc, openssl)
echo "[2/4] Building static dependencies..."
cd "$SCRIPT_DIR/scripts"
chmod +x *.sh
./build_deps.sh
cd "$SCRIPT_DIR"

# Build XMRig
echo "[3/4] Building XMRig..."
mkdir -p build
cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_OPENCL=OFF \
    -DWITH_CUDA=OFF \
    -DWITH_HWLOC=ON \
    -DWITH_TLS=ON \
    -DWITH_ASM=ON \
    -DWITH_EMBEDDED_CONFIG=OFF \
    -DBUILD_STATIC=ON \
    -DUV_INCLUDE_DIR="$SCRIPT_DIR/scripts/deps/include" \
    -DUV_LIBRARY="$SCRIPT_DIR/scripts/deps/lib/libuv.a" \
    -DHWLOC_INCLUDE_DIR="$SCRIPT_DIR/scripts/deps/include" \
    -DHWLOC_LIBRARY="$SCRIPT_DIR/scripts/deps/lib/libhwloc.a" \
    -DOPENSSL_ROOT_DIR="$SCRIPT_DIR/scripts/deps"

make -j$(nproc)
strip xmrig

# Copy to release
echo "[4/4] Copying binary..."
mkdir -p "$SCRIPT_DIR/release"
cp xmrig "$SCRIPT_DIR/release/"

cd "$SCRIPT_DIR"

echo ""
echo "=== Build complete! ==="
echo "Binary: release/xmrig"
echo "Donate level: 0%"
echo ""
echo "To verify: ./release/xmrig --donate-level"
echo "To package for HiveOS: ./package_hiveos.sh --skip-build"
