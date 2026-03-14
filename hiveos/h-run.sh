#!/usr/bin/env bash

# XMRig Custom Miner for HiveOS (0% dev fee)

# Figure out where we are installed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[xmrig] Script dir: $SCRIPT_DIR"
echo "[xmrig] Running as user: $(whoami), HOME=$HOME"
echo "[xmrig] Contents of script dir:"
ls -la "$SCRIPT_DIR/" 2>&1

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

# Copy config.json to ALL possible XMRig default search locations
CONFIG_SRC="$SCRIPT_DIR/config.json"
if [[ -f "$CONFIG_SRC" ]]; then
    echo "[xmrig] Found config at: $CONFIG_SRC"
    # Copy to $HOME paths (works regardless of whether running as root or user)
    cp "$CONFIG_SRC" "$HOME/.xmrig.json" 2>/dev/null
    mkdir -p "$HOME/.config" 2>/dev/null
    cp "$CONFIG_SRC" "$HOME/.config/xmrig.json" 2>/dev/null
    # Also copy to /root/ in case running via sudo
    cp "$CONFIG_SRC" /root/.xmrig.json 2>/dev/null
    mkdir -p /root/.config 2>/dev/null
    cp "$CONFIG_SRC" /root/.config/xmrig.json 2>/dev/null
    # Also copy to /home/user/ explicitly (common HiveOS user)
    cp "$CONFIG_SRC" /home/user/.xmrig.json 2>/dev/null
    mkdir -p /home/user/.config 2>/dev/null
    cp "$CONFIG_SRC" /home/user/.config/xmrig.json 2>/dev/null
    echo "[xmrig] Copied config to $HOME/.xmrig.json, /root/.xmrig.json, /home/user/.xmrig.json"
else
    echo "[xmrig] WARNING: No config.json found at $CONFIG_SRC"
    ls -la "$SCRIPT_DIR/" 2>&1
fi

# Override pool/wallet/algo from flight sheet via CLI args if set
CLI_ARGS="--donate-level=0"
[[ -n "$CUSTOM_URL" ]] && CLI_ARGS="$CLI_ARGS -o $CUSTOM_URL"
WALLET="${CUSTOM_TEMPLATE:-$CUSTOM_URL2}"
[[ -n "$WALLET" ]] && CLI_ARGS="$CLI_ARGS -u $WALLET"
[[ -n "$CUSTOM_PASS" ]] && CLI_ARGS="$CLI_ARGS -p $CUSTOM_PASS"
[[ -n "$CUSTOM_ALGO" ]] && CLI_ARGS="$CLI_ARGS --algo=$CUSTOM_ALGO"
[[ -n "$WORKER_NAME" ]] && CLI_ARGS="$CLI_ARGS --rig-id=$WORKER_NAME"
[[ -n "$CUSTOM_USER_CONFIG" ]] && CLI_ARGS="$CLI_ARGS $CUSTOM_USER_CONFIG"

echo "[xmrig] Starting: $SCRIPT_DIR/xmrig $CLI_ARGS"

cd "$SCRIPT_DIR"
"$SCRIPT_DIR/xmrig" $CLI_ARGS
