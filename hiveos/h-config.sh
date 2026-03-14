#!/usr/bin/env bash
#
# h-config.sh — Generate XMRig config.json from HiveOS flight sheet parameters
#

. /hive/miners/custom/xmrig-custom/h-manifest.conf

MINER_DIR="/hive/miners/custom/$CUSTOM_NAME"
MINER_CONFIG="$MINER_DIR/config.json"

# Wallet and worker
[[ -z "$CUSTOM_TEMPLATE" ]] && CUSTOM_TEMPLATE="%WAL%.%WORKER_NAME%"

# Resolve variables in template
TEMPLATE="$CUSTOM_TEMPLATE"
TEMPLATE="${TEMPLATE/\%WAL\%/$CUSTOM_URL2}"
TEMPLATE="${TEMPLATE/\%WORKER_NAME\%/$WORKER_NAME}"

# Pool URL
POOL_URL="$CUSTOM_URL"

# Algorithm
ALGO="$CUSTOM_ALGO"

# Extra config (user can pass JSON overrides)
EXTRA_CONFIG="$CUSTOM_USER_CONFIG"

# Build the config.json
cat > "$MINER_CONFIG" <<CONFIGEOF
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
        "port": $CUSTOM_API_PORT,
        "access-token": null,
        "restricted": true
    },
    "pools": [
        {
            "url": "$POOL_URL",
            "user": "$TEMPLATE",
            "pass": "${CUSTOM_PASS:-x}",
            "algo": ${ALGO:+\"$ALGO\"}${ALGO:-null},
            "rig-id": "$WORKER_NAME",
            "keepalive": true,
            "tls": ${CUSTOM_TLS:-false}
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
    }
}
CONFIGEOF

# If user passed extra JSON config, merge it via jq if available
if [[ -n "$EXTRA_CONFIG" ]] && command -v jq &>/dev/null; then
    echo "$EXTRA_CONFIG" | jq -s '.[0] * .[1]' "$MINER_CONFIG" - > "${MINER_CONFIG}.tmp" && \
        mv "${MINER_CONFIG}.tmp" "$MINER_CONFIG"
fi
