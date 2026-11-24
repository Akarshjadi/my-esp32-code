#!/bin/zsh
# one-click repeater: configure + flash-free setup of the ESP32 NAT router
# and poll its uplink signal strength into a live graph.
#
# Usage:
#   1. Connect Mac Wi-Fi to the ESP32's setup AP: SSID "toddler" PASS "havemebaby"
#   2. ./repeater.sh "<uplink_SSID>" "<uplink_PASS>" "<ap_SSID>" "<ap_PASS>"
#   ./repeater.sh                          # use saved config from .repeater.conf
#   ./repeater.sh --graph-only             # just poll the signal graph
#
# What it does (one click):
#   POST http://192.168.4.1:8080/apply  -> ESP32 stores uplink STA + downlink AP,
#                                           restarts in 1 s and becomes the repeater.
#   GET  http://192.168.4.1:8080/api    -> {"strength": -76} polled into signal.csv
#                                           + a live SVG/HTML graph (graph.html).
#
# No firmware rebuild needed: this uses the web interface the firmware ships with.

set -u
AP_IP="${AP_IP:-192.168.4.1}"
PORT="${PORT:-8080}"
BASE="http://$AP_IP:$PORT"
HERE="${0:A:h}"
CSV="${HERE}/signal.csv"
HTML="${HERE}/graph.html"
CONF="${HERE}/.repeater.conf"

# ---------- args ----------
graph_only=0
if [[ -n "${1:-}" && "${1}" == "--graph-only" ]]; then
  graph_only=1; shift
fi
if (( $# >= 4 )); then
  STA_SSID=$1; STA_PASS=$2; AP_SSID=$3; AP_PASS=$4
else
  if [[ -f "$CONF" ]]; then
    source "$CONF"
  else
    echo "No config. Either pass args or create $CONF:"
    echo '  echo "STA_SSID=MyWifi STA_PASS=secret AP_SSID=Repeater AP_PASS=pass123" > '"$CONF"
    exit 1
  fi
fi

# ---------- one click: apply repeater config ----------
apply() {
  print "\n[apply] POST /apply -> uplink '$STA_SSID' / downlink AP '$AP_SSID'"
  local resp
  resp=$(curl -s -m 10 -o /dev/null -w "%{http_code}" \
    -X POST "$BASE/apply" \
    --data-urlencode "func=config" \
    --data-urlencode "ssid=$STA_SSID" \
    --data-urlencode "password=$STA_PASS" \
    --data-urlencode "ap_ssid=$AP_SSID" \
    --data-urlencode "ap_password=$AP_PASS" \
    --data-urlencode "x=x" 2>&1) || { echo "ERROR: cannot reach $BASE"; echo "  Is Mac Wi-Fi on the 'toddler' setup AP?"; exit 1; }
  print "[apply] HTTP $resp — ESP32 restarting into repeater mode in ~1 s"
  echo "STA_SSID=$STA_SSID STA_PASS=$STA_PASS AP_SSID=$AP_SSID AP_PASS=$AP_PASS" > "$CONF"
  print "[apply] config saved to $CONF (reuse next time: $0)"
}

if (( ! graph_only )); then apply; fi

# ---------- wait for the repeater to come back up ----------
print "\n[wait] for $BASE/api to answer..."
for i in {1..40}; do
  sleep 1
  if code=$(curl -s -m 3 -o /dev/null -w "%{http_code}" "$BASE/api" 2>/dev/null); then
    if [[ "$code" == "200" ]]; then
      print "[wait] up after ${i}s — repeater is live."
      break
    fi
  fi
done

# ---------- poll RSSI into a CSV + regenerate a self-contained graph ----------
# Each call: one /api sample appended to $CSV (last 200 kept) and $HTML rebuilt.
# The HTML auto-refreshes every 3 s, so when you open it later the live loop
# in the main flow keeps feeding it. Use poll_once for a single shot.
poll_once() {
  local data rssi
  data=$(curl -s -m 5 "$BASE/api" 2>/dev/null)
  rssi=$(python3 - "$data" <<'PY'
import sys, json
try:
    print(int(json.loads(sys.argv[1]).get("strength", "0")))
except Exception:
    print("0")
PY
)
  [[ -z "$rssi" || "$rssi" == "0" ]] && rssi=-99   # 0 means not connected yet
  printf "%s,%s\n" "$(date +%H:%M:%S)" "$rssi" >> "$CSV"
  tail -200 "$CSV" > "$CSV.tmp" && mv "$CSV.tmp" "$CSV"

  python3 - "$CSV" "$HTML" <<'PY'
import sys, html
csv, out = sys.argv[1], sys.argv[2]
rows = [l.strip().split(",") for l in open(csv) if "," in l and l.split(",")[1].lstrip("-").isdigit()]
vals = [int(r[1]) for r in rows]
n = len(vals) or 1
w, h, pad = 900, 320, 40
lo, hi = -100, -30
def x(i): return pad + i*(w-2*pad)/max(n-1,1)
def y(v): return pad + (v-hi)/(hi-lo)*(h-2*pad)
pts = " ".join(f"{x(i):.1f},{y(v):.1f}" for i,v in enumerate(vals))
last = vals[-1] if vals else 0
col = "#2ecc71" if last >= -50 else "#f1c40f" if last >= -70 else "#e74c3c"
svg = f'''<svg viewBox="0 0 {w} {h}" width="{w}" height="{h}" xmlns="http://www.w3.org/2000/svg">
<rect width="{w}" height="{h}" fill="#0d1117"/>
<line x1="{pad}" y1="{y(-70)}" x2="{w-pad}" y2="{y(-70)}" stroke="#30363d" stroke-dasharray="4 4"/>
<text x="{w-pad-60}" y="{y(-70)-4}" fill="#8b949e" font-size="12">-70 dB (antenna threshold)</text>
<line x1="{pad}" y1="{h-pad}" x2="{w-pad}" y2="{h-pad}" stroke="#30363d"/>
<line x1="{pad}" y1="{pad}" x2="{pad}" y2="{h-pad}" stroke="#30363d"/>
<polyline fill="none" stroke="{col}" stroke-width="2.5" points="{pts}"/>
<circle cx="{x(n-1)}" cy="{y(last)}" r="4" fill="{col}"/>
<text x="{pad}" y="20" fill="#e6edf3" font-size="16" font-family="monospace">
Uplink RSSI {last} dB  ({n} samples)  {html.escape(rows[-1][0]) if rows else ""}</text>
</svg>'''
open(out,"w").write(f'''<!doctype html><meta charset="utf-8">
<title>ESP32 repeater — uplink signal</title>
<body style="margin:0;background:#0d1117;color:#e6edf3;font-family:monospace">
<div style="padding:16px">ESP32 one-click repeater — uplink signal strength. Auto-refresh every 3 s.</div>
{svg}
<script>setTimeout(function(){{location.reload()}},3000)</script>''')
PY
}

# initial CSV header
[[ -f "$CSV" ]] || echo "time,rssi" > "$CSV"

if (( graph_only )); then
  print "[graph] single sample -> $HTML (open it in a browser)"
  poll_once
  exit 0
fi

# keep updating the graph in the background so the antenna-placement
# picture keeps filling in while you move around the room.
print "\n[graph] live updates -> $HTML  (Ctrl-C here to stop)"
print "open it:  open $HTML"
trap 'kill %1 2>/dev/null; exit 0' INT
while :; do
  poll_once
  sleep 3
done &
