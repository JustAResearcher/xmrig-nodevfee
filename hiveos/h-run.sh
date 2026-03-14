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

# Write config.json next to binary (guaranteed pickup)
cat > "$SCRIPT_DIR/config.json" <<'ENDJSON'
{
    "autosave": false,
    "donate-level": 0,
    "donate-over-proxy": 0,
    "cpu": true,
    "opencl": false,
    "cuda": false,
    "log-file": null,
    "http": {
        "enabled": true,
        "host": "127.0.0.1",
        "port": 60080,
        "access-token": null,
        "restricted": true
    },
    "pools": [
        {
            "url": "xmr-us.kryptex.network:7029",
            "user": "89eWJ7ccdVr3GHBAYsKG28eqWcn2PMWzYeFE5xtgWzg1UimfWS62Qq4VpUSQrX3vaDeMTAMhBVR885RxkLzXNkmFV9yXvcg",
            "pass": "x",
            "algo": null,
            "rig-id": null,
            "keepalive": true,
            "tls": false,
            "nicehash": false,
            "enabled": true
        }
    ],
    "randomx": {
        "init": -1,
        "init-avx2": -1,
        "mode": "auto",
        "1gb-pages": true,
        "rdmsr": true,
        "wrmsr": true,
        "cache_qos": false,
        "numa": true,
        "scratchpad_prefetch_mode": 1
    },
    "print-time": 60,
    "retries": 5,
    "retry-pause": 5
}
ENDJSON

cd "$SCRIPT_DIR"
exec "$SCRIPT_DIR/xmrig" --donate-level=0
