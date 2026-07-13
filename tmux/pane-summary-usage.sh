#!/usr/bin/env bash
# Reports how much the tmux pane-summary feature has spent (equivalent cost)
# and how many model calls it has made. Reads the log written by pane-summary.sh.
#
#   pane-summary-usage.sh          # all-time totals
#   pane-summary-usage.sh today    # only calls since local midnight

log="${TMPDIR:-/tmp}/tmux-pane-summary/usage.log"
[ -f "$log" ] || { echo "No usage yet (log: $log)"; exit 0; }

python3 - "$log" "${1:-all}" <<'PY'
import sys,time
log,scope=sys.argv[1],sys.argv[2]
cutoff=0
if scope=="today":
    t=time.localtime(); cutoff=time.mktime((t.tm_year,t.tm_mon,t.tm_mday,0,0,0,0,0,-1))
n=cost=itok=otok=cread=0
for ln in open(log):
    p=ln.rstrip("\n").split("\t")
    if len(p)<6: continue
    try: ts=int(p[0])
    except: continue
    if ts<cutoff: continue
    n+=1; cost+=float(p[2]); itok+=int(p[3]); otok+=int(p[4]); cread+=int(p[5])
label="today" if scope=="today" else "all-time"
print(f"pane-summary usage ({label}):")
print(f"  calls           {n}")
print(f"  equiv. cost     ${cost:.4f}")
print(f"  input tokens    {itok:,}")
print(f"  output tokens   {otok:,}")
print(f"  cache-read tok  {cread:,}")
if n: print(f"  avg / call      ${cost/n:.4f}")
PY
