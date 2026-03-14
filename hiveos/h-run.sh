#!/usr/bin/env bash

# XMRig Custom Miner for HiveOS (0% dev fee)
# Config is embedded in binary — no config.json needed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Enable huge pages
sysctl -w vm.nr_hugepages=1280 2>/dev/null
echo "always" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null

cd "$SCRIPT_DIR"
exec "$SCRIPT_DIR/xmrig" --donate-level=0
