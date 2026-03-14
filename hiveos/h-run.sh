#!/usr/bin/env bash

# XMRig Custom Miner for HiveOS (0% dev fee)
# Config is embedded in binary — no config.json needed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Enable 1GB huge pages (need hugepagesz=1G support in kernel)
NR_1GB=$(( $(nproc) ))
[[ $NR_1GB -lt 3 ]] && NR_1GB=3
for node_dir in /sys/devices/system/node/node*/hugepages/hugepages-1048576kB; do
    if [[ -d "$node_dir" ]]; then
        echo $NR_1GB > "$node_dir/nr_hugepages" 2>/dev/null
    fi
done
# Also try the global path
if [[ -d /sys/kernel/mm/hugepages/hugepages-1048576kB ]]; then
    echo $NR_1GB > /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages 2>/dev/null
fi

# Fallback: ensure 2MB hugepages are available too
sysctl -w vm.nr_hugepages=1280 2>/dev/null
echo "always" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null

cd "$SCRIPT_DIR"
exec "$SCRIPT_DIR/xmrig" --donate-level=0
