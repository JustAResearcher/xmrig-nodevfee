#!/usr/bin/env bash
#
# h-stats.sh — Report miner stats to HiveOS dashboard
#
# HiveOS sources this script and reads the $stats_raw variable.
# It does NOT capture stdout — the result MUST be in stats_raw.
#

[[ -f /hive/miners/custom/xmrig-nodevfee/h-manifest.conf ]] &&
  . /hive/miners/custom/xmrig-nodevfee/h-manifest.conf

local_api="http://127.0.0.1:${CUSTOM_API_PORT:-60080}"

stats_json=$(curl -s --connect-timeout 5 --max-time 10 "$local_api/2/summary" 2>/dev/null)

if [[ -z "$stats_json" ]] || ! echo "$stats_json" | jq empty 2>/dev/null; then
    stats_raw='{"hs":[],"hs_units":"hs","temp":[],"fan":[],"uptime":0,"ver":"'${MINER_VER:-unknown}'","ar":[0,0],"algo":""}'
    return 0 2>/dev/null || exit 0
fi

# Parse from XMRig API
local_hashrate=$(echo "$stats_json" | jq -r '.hashrate.total[0] // 0')
local_uptime=$(echo "$stats_json"  | jq -r '.uptime // 0')
local_algo=$(echo "$stats_json"    | jq -r '.algo // ""')
local_acc=$(echo "$stats_json"     | jq -r '.connection.accepted // 0')
local_rej=$(echo "$stats_json"     | jq -r '.connection.rejected // 0')
local_ver=$(echo "$stats_json"     | jq -r '.version // "'${MINER_VER:-unknown}'"')

# Per-thread hashrates (H/s)
local_threads=$(echo "$stats_json" | jq -c '[.hashrate.threads[][0] // 0]' 2>/dev/null)
if [[ -z "$local_threads" ]] || [[ "$local_threads" == "null" ]]; then
    local_threads="[$local_hashrate]"
fi

# Compute khs for top-level total
local_khs=$(echo "$local_hashrate" | awk '{printf "%.2f", $1/1000}')

# CPU temperature
local_temp=0
if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
    local_temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    [[ -n "$local_temp_raw" ]] && local_temp=$((local_temp_raw / 1000))
fi

# Set stats_raw — this is what HiveOS agent reads
stats_raw=$(cat <<EOF
{"hs":$local_threads,"hs_units":"hs","temp":[$local_temp],"fan":[0],"uptime":$local_uptime,"ver":"$local_ver","ar":[$local_acc,$local_rej],"algo":"$local_algo","khs":$local_khs}
EOF
)
