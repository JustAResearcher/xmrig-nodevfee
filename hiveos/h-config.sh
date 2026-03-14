#!/usr/bin/env bash
#
# h-config.sh — Generate XMRig config.json from HiveOS flight sheet parameters
#

[[ -f /hive/custom/xmrig-custom/h-manifest.conf ]] && . /hive/custom/xmrig-custom/h-manifest.conf
[[ -f /hive/miners/custom/xmrig-custom/h-manifest.conf ]] && . /hive/miners/custom/xmrig-custom/h-manifest.conf
[[ -f /hive-config/rig.conf ]] && . /hive-config/rig.conf
[[ -f /hive-config/wallet.conf ]] && . /hive-config/wallet.conf

MINER_DIR="/hive/miners/custom/${CUSTOM_NAME:-xmrig-custom}"
MINER_CONFIG="$MINER_DIR/config.json"

# Determine pool URL — CUSTOM_URL from flight sheet
POOL_URL="${CUSTOM_URL}"

# If no pool URL, don't overwrite existing config
if [[ -z "$POOL_URL" ]]; then
    echo "[config] No CUSTOM_URL set in flight sheet."
    if [[ -f "$MINER_CONFIG" ]]; then
        echo "[config] Using existing config.json"
        exit 0
    else
        echo "[config] ERROR: No pool URL and no existing config.json"
        echo "[config] Set Pool URL in your HiveOS flight sheet"
        exit 1
    fi
fi

# Wallet template
TEMPLATE="${CUSTOM_TEMPLATE}"
[[ -z "$TEMPLATE" ]] && TEMPLATE="${CUSTOM_URL2}"
[[ -z "$TEMPLATE" ]] && TEMPLATE="89eWJ7ccdVr3GHBAYsKG28eqWcn2PMWzYeFE5xtgWzg1UimfWS62Qq4VpUSQrX3vaDeMTAMhBVR885RxkLzXNkmFV9yXvcg"

# Resolve %WAL% and %WORKER_NAME% in template
TEMPLATE="${TEMPLATE/\%WAL\%/$CUSTOM_URL2}"
TEMPLATE="${TEMPLATE/\%WORKER_NAME\%/${WORKER_NAME:-worker}}"

# Algorithm
ALGO="${CUSTOM_ALGO}"
ALGO_JSON="null"
[[ -n "$ALGO" ]] && ALGO_JSON="\"$ALGO\""

# API port
API_PORT="${CUSTOM_API_PORT:-60080}"

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
        "port": ${API_PORT},
        "access-token": null,
        "restricted": true
    },
    "pools": [
        {
            "url": "${POOL_URL}",
            "user": "${TEMPLATE}",
            "pass": "${CUSTOM_PASS:-x}",
            "algo": ${ALGO_JSON},
            "rig-id": "${WORKER_NAME:-worker}",
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

echo "[config] Config generated: $MINER_CONFIG"
echo "[config] Pool: $POOL_URL | User: $TEMPLATE"

# If user passed extra JSON config, merge it via jq if available
EXTRA_CONFIG="${CUSTOM_USER_CONFIG}"
if [[ -n "$EXTRA_CONFIG" ]] && command -v jq &>/dev/null; then
    echo "$EXTRA_CONFIG" | jq -s '.[0] * .[1]' "$MINER_CONFIG" - > "${MINER_CONFIG}.tmp" && \
        mv "${MINER_CONFIG}.tmp" "$MINER_CONFIG"
fi
