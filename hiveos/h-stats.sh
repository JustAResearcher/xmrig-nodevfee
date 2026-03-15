#!/usr/bin/env bash
#
# h-stats.sh — Report miner stats to HiveOS dashboard
#
# HiveOS agent (/hive/bin/agent) sources this script in a subshell then reads:
#   $khs   — total hashrate in kH/s
#   $stats — JSON string with detailed stats
#
# The agent does: { source h-manifest.conf; source h-config.sh; source h-stats.sh; } 1>&2
# Then: printf "%q\n" "$khs" and echo "$stats"
#
# IMPORTANT: The agent uses MINER_DIR=/hive/miners/custom (not the subdirectory),
# so this file must also exist at /hive/miners/custom/h-stats.sh
#

# Source manifest if available (may already be sourced by agent)
[[ -z "$CUSTOM_API_PORT" && -f /hive/miners/custom/xmrig-nodevfee/h-manifest.conf ]] &&
  . /hive/miners/custom/xmrig-nodevfee/h-manifest.conf

local_api="http://127.0.0.1:${CUSTOM_API_PORT:-60080}"

stats_json=$(curl -s --connect-timeout 5 --max-time 10 "$local_api/2/summary" 2>/dev/null)

if [[ -z "$stats_json" ]] || ! echo "$stats_json" | jq empty 2>/dev/null; then
    khs=0
    stats='{"hs":[],"hs_units":"hs","temp":[],"fan":[],"uptime":0,"ver":"unknown","ar":[0,0],"algo":""}'
    return 0 2>/dev/null
fi

# Parse from XMRig API
local_hashrate=$(echo "$stats_json" | jq -r '.hashrate.total[0] // 0')
local_uptime=$(echo "$stats_json"  | jq -r '.uptime // 0')
local_algo=$(echo "$stats_json"    | jq -r '.algo // ""')
local_acc=$(echo "$stats_json"     | jq -r '.connection.accepted // 0')
local_rej=$(echo "$stats_json"     | jq -r '.connection.rejected // 0')
local_ver=$(echo "$stats_json"     | jq -r '.version // "unknown"')

# Per-thread hashrates (H/s)
local_threads=$(echo "$stats_json" | jq -c '[.hashrate.threads[][0] // 0]' 2>/dev/null)
[[ -z "$local_threads" || "$local_threads" == "null" ]] && local_threads="[$local_hashrate]"

# CPU temperature
local_temp=0
[[ -f /sys/class/thermal/thermal_zone0/temp ]] && local_temp=$(($(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0) / 1000))

# khs — the agent reads this variable for total_khs on the dashboard
khs=$(echo "$local_hashrate" | awk '{printf "%.2f", $1/1000}')

# stats — the agent reads this variable (NOT stats_raw) for the JSON payload
stats='{"hs":'$local_threads',"hs_units":"hs","temp":['$local_temp'],"fan":[0],"uptime":'$local_uptime',"ver":"'$local_ver'","ar":['$local_acc','$local_rej'],"algo":"'$local_algo'"}'

# Also set stats_raw for compatibility
stats_raw="$stats"
