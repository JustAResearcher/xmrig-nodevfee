#!/usr/bin/env bash
#
# h-config.sh — Create config.json for XMRig (0% dev fee)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

echo "[h-config] Config written to $SCRIPT_DIR/config.json"
