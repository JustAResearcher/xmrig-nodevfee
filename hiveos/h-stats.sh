#!/usr/bin/env bash
#
# h-stats.sh — Report miner stats to HiveOS dashboard
#
# HiveOS expects this script to output a JSON object with:
#   hs       — array of hashrates per thread (or single element for total)
#   hs_units — hashrate units ("khs", "hs", "mhs")
#   temp     — array of GPU temps (empty for CPU-only)
#   fan      — array of GPU fan speeds (empty for CPU-only)
#   uptime   — miner uptime in seconds
#   ver      — miner version string
#   ar       — [accepted, rejected] share counts
#   algo     — current algorithm
#

. /hive/miners/custom/xmrig-custom/h-manifest.conf

API_URL="http://127.0.0.1:${CUSTOM_API_PORT}"

# Fetch stats from XMRig HTTP API
stats=$(curl -s --connect-timeout 5 --max-time 10 "$API_URL/2/summary" 2>/dev/null)

if [[ -z "$stats" ]] || ! echo "$stats" | jq empty 2>/dev/null; then
    echo '{"hs":[],"hs_units":"khs","temp":[],"fan":[],"uptime":0,"ver":"'$MINER_VER'","ar":[0,0],"algo":""}'
    exit 0
fi

# Parse stats using jq
hashrate_total=$(echo "$stats" | jq -r '.hashrate.total[0] // 0')
uptime=$(echo "$stats" | jq -r '.uptime // 0')
algo=$(echo "$stats" | jq -r '.algo // ""')
accepted=$(echo "$stats" | jq -r '.connection.accepted // 0')
rejected=$(echo "$stats" | jq -r '.connection.rejected // 0')
version=$(echo "$stats" | jq -r '.version // "'$MINER_VER'"')

# Per-thread hashrates
thread_hashrates=$(echo "$stats" | jq -c '[.hashrate.threads[][0] // 0]' 2>/dev/null)
if [[ -z "$thread_hashrates" ]] || [[ "$thread_hashrates" == "null" ]]; then
    thread_hashrates="[$hashrate_total]"
fi

# CPU temperature (try lm-sensors / sysfs)
cpu_temp=0
if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
    cpu_temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    if [[ -n "$cpu_temp_raw" ]]; then
        cpu_temp=$((cpu_temp_raw / 1000))
    fi
fi

# Build output JSON — hashrates in H/s
cat <<STATSEOF
{
    "hs": $thread_hashrates,
    "hs_units": "hs",
    "temp": [$cpu_temp],
    "fan": [0],
    "uptime": $uptime,
    "ver": "$version",
    "ar": [$accepted, $rejected],
    "algo": "$algo"
}
STATSEOF
