#!/usr/bin/env bash

# XMRig Custom Miner for HiveOS (0% dev fee)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Enable 1GB huge pages (need hugepagesz=1G support in kernel)
NR_1GB=$(( $(nproc) ))
[[ $NR_1GB -lt 3 ]] && NR_1GB=3
for node_dir in /sys/devices/system/node/node*/hugepages/hugepages-1048576kB; do
    if [[ -d "$node_dir" ]]; then
        echo $NR_1GB > "$node_dir/nr_hugepages" 2>/dev/null
    fi
done
if [[ -d /sys/kernel/mm/hugepages/hugepages-1048576kB ]]; then
    echo $NR_1GB > /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages 2>/dev/null
fi
sysctl -w vm.nr_hugepages=1280 2>/dev/null
echo "always" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null

# Write config.json next to binary
cat > "$SCRIPT_DIR/config.json" <<'ENDJSON'
{
    "autosave": true,
    "cpu": true,
    "opencl": false,
    "cuda": false,
    "pools": [
        {
            "coin": "monero",
            "algo": "rx/0",
            "url": "xmr-us.kryptex.network:7029",
            "user": "89eWJ7ccdVr3GHBAYsKG28eqWcn2PMWzYeFE5xtgWzg1UimfWS62Qq4VpUSQrX3vaDeMTAMhBVR885RxkLzXNkmFV9yXvcg",
            "pass": "x",
            "tls": false,
            "keepalive": true,
            "nicehash": false
        }
    ]
}
ENDJSON

cd "$SCRIPT_DIR"
exec "$SCRIPT_DIR/xmrig" --donate-level=0
