#!/usr/bin/env bash
#
# h-run.sh — Start XMRig for HiveOS
#

. /hive/miners/custom/xmrig-custom/h-manifest.conf

MINER_DIR="/hive/miners/custom/$CUSTOM_NAME"
MINER_BIN="$MINER_DIR/xmrig"
MINER_CONFIG="$MINER_DIR/config.json"
MINER_LOG_DIR="/var/log/miner/$CUSTOM_NAME"

# Create log directory
mkdir -p "$MINER_LOG_DIR"

# Generate config
source "$MINER_DIR/h-config.sh"

# Enable 1GB huge pages (one per CPU thread for RandomX)
echo "[hugepages] Enabling 1GB huge pages..."
NR_1GB=$(nproc)
sysctl -w vm.nr_hugepages=$NR_1GB 2>/dev/null

for node in $(find /sys/devices/system/node/node* -maxdepth 0 -type d 2>/dev/null); do
    echo $NR_1GB > "$node/hugepages/hugepages-1048576kB/nr_hugepages" 2>/dev/null
done

# Verify 1GB pages were allocated
ALLOC_1GB=0
for node in $(find /sys/devices/system/node/node* -maxdepth 0 -type d 2>/dev/null); do
    count=$(cat "$node/hugepages/hugepages-1048576kB/nr_hugepages" 2>/dev/null || echo 0)
    ALLOC_1GB=$((ALLOC_1GB + count))
done

if [[ "$ALLOC_1GB" -gt 0 ]]; then
    echo "[hugepages] Successfully allocated ${ALLOC_1GB} x 1GB huge pages"
else
    echo "[hugepages] WARNING: Could not allocate 1GB pages (need kernel boot param: hugepagesz=1G hugepages=N)"
    echo "[hugepages] Falling back to 2MB huge pages..."
    sysctl -w vm.nr_hugepages=1280 2>/dev/null
fi

# Enable transparent huge pages as fallback
echo "always" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null

# Run the miner
cd "$MINER_DIR"
exec ./xmrig --config="$MINER_CONFIG" --donate-level=0 2>&1 | tee "$MINER_LOG_DIR/$CUSTOM_NAME.log"
