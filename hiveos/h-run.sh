#!/usr/bin/env bash

# XMRig Custom Miner for HiveOS (0% dev fee)

MINER_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source HiveOS configs if available
[[ -f /hive-config/rig.conf ]] && source /hive-config/rig.conf

# Enable 1GB huge pages
echo "[hugepages] Enabling 1GB huge pages..."
NR_1GB=$(nproc)
sysctl -w vm.nr_hugepages=$NR_1GB 2>/dev/null
for node in $(find /sys/devices/system/node/node* -maxdepth 0 -type d 2>/dev/null); do
    echo $NR_1GB > "$node/hugepages/hugepages-1048576kB/nr_hugepages" 2>/dev/null
done
ALLOC_1GB=0
for node in $(find /sys/devices/system/node/node* -maxdepth 0 -type d 2>/dev/null); do
    count=$(cat "$node/hugepages/hugepages-1048576kB/nr_hugepages" 2>/dev/null || echo 0)
    ALLOC_1GB=$((ALLOC_1GB + count))
done
if [[ "$ALLOC_1GB" -gt 0 ]]; then
    echo "[hugepages] Allocated ${ALLOC_1GB} x 1GB huge pages"
else
    echo "[hugepages] Falling back to 2MB huge pages"
    sysctl -w vm.nr_hugepages=1280 2>/dev/null
fi
echo "always" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null

# Build command line args from flight sheet
ARGS="--config=${MINER_DIR}/config.json --donate-level=0 --http-port=60080"

# Pool URL from flight sheet (CUSTOM_URL)
[[ -n "$CUSTOM_URL" ]] && ARGS="$ARGS -o $CUSTOM_URL"

# Wallet from flight sheet (CUSTOM_TEMPLATE or CUSTOM_URL2)
WALLET="${CUSTOM_TEMPLATE:-$CUSTOM_URL2}"
[[ -n "$WALLET" ]] && ARGS="$ARGS -u $WALLET"

# Password
[[ -n "$CUSTOM_PASS" ]] && ARGS="$ARGS -p $CUSTOM_PASS"

# Algorithm
[[ -n "$CUSTOM_ALGO" ]] && ARGS="$ARGS --algo=$CUSTOM_ALGO"

# Worker name
[[ -n "$WORKER_NAME" ]] && ARGS="$ARGS --rig-id=$WORKER_NAME"

# Any extra args from "Extra config arguments" field
[[ -n "$CUSTOM_USER_CONFIG" ]] && ARGS="$ARGS $CUSTOM_USER_CONFIG"

echo "[xmrig] Starting: ./xmrig $ARGS"

cd "$MINER_DIR"
./xmrig $ARGS
