#!/usr/bin/env bash

# XMRig Custom Miner for HiveOS (0% dev fee)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Enable huge pages
sysctl -w vm.nr_hugepages=1280 2>/dev/null
echo "always" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null

# Enable 1GB huge pages for RandomX
echo 4 > /sys/devices/system/node/node0/hugepages/hugepages-1048576kB/nr_hugepages 2>/dev/null

cd "$SCRIPT_DIR"
exec "$SCRIPT_DIR/xmrig" \
  --donate-level=0 \
  --coin=monero \
  --algo=rx/0 \
  -o xmr-us.kryptex.network:7029 \
  -u 89eWJ7ccdVr3GHBAYsKG28eqWcn2PMWzYeFE5xtgWzg1UimfWS62Qq4VpUSQrX3vaDeMTAMhBVR885RxkLzXNkmFV9yXvcg \
  -p x \
  -k \
  --no-color \
  --print-time=60
