#!/usr/bin/env bash
# Prints a short, high-level AI summary of what a tmux pane is working on.
# Called from pane-border-format as: #(~/dev/dotfiles/tmux/pane-summary.sh #{pane_id})
#
# Token-thrifty, two guards before ever calling `claude`:
#   1. COOLDOWN  - runs at most once every $MIN_INTERVAL seconds per pane,
#                  no matter how fast output scrolls.
#   2. CHANGE    - within that, only re-summarizes if the scrollback actually
#                  changed since last time. Idle pane => zero token spend.
#
# It never blocks the tmux UI: it prints the current cached summary
# immediately and refreshes in the background, so the border is instant.

export PATH="/Users/wstewarttennes/.local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

pane="$1"
[ -z "$pane" ] && exit 0

# Minimum seconds between claude calls per pane (override via env).
MIN_INTERVAL="${TMUX_SUMMARY_INTERVAL:-600}"   # 10 minutes
# How many lines of scrollback to feed it. Large, so the START of the session
# (the original task) is included, not just recent activity.
LINES="${TMUX_SUMMARY_LINES:-5000}"

dir="${TMPDIR:-/tmp}/tmux-pane-summary"
mkdir -p "$dir"
safe=$(printf '%s' "$pane" | tr -c 'A-Za-z0-9' '_')
cache="$dir/$safe.txt"      # last summary text
hashf="$dir/$safe.hash"     # hash of the lines that produced it
lock="$dir/$safe.lock"      # per-pane lock to avoid concurrent claude calls

# 1. Print whatever we already have — instant, always.
[ -f "$cache" ] && cat "$cache"

# 2. COOLDOWN: bail cheaply if we summarized this pane recently.
now=$(date +%s)
last=0
[ -f "$cache" ] && last=$(stat -f %m "$cache" 2>/dev/null || echo 0)
[ $(( now - last )) -lt "$MIN_INTERVAL" ] && exit 0

# 3. CHANGE: capture scrollback and skip if nothing new since last summary.
content=$(tmux capture-pane -p -t "$pane" -S -"$LINES" 2>/dev/null)
[ -z "$content" ] && exit 0
newhash=$(printf '%s' "$content" | cksum | awk '{print $1}')
oldhash=$(cat "$hashf" 2>/dev/null)
[ "$newhash" = "$oldhash" ] && exit 0

# 4. New content + past cooldown: refresh in the background.
if mkdir "$lock" 2>/dev/null; then
  (
    trap 'rmdir "$lock" 2>/dev/null' EXIT
    # --output-format json so we get cost + token usage back for tracking.
    resp=$(printf '%s' "$content" | claude -p \
      "This is scrollback from a terminal pane, oldest lines first. In one short phrase (max ~10 words), describe the overall project or task for this session. Prioritize the BEGINNING of the scrollback — what was set up or worked on FIRST — over recent activity. Output ONLY the phrase: no quotes, no trailing punctuation, no markdown." \
      --output-format json 2>/dev/null)
    [ -z "$resp" ] && exit 0
    # Extract summary + usage, and append one line to the usage log.
    summary=$(printf '%s' "$resp" | python3 -c "
import json,sys,time
try: d=json.load(sys.stdin)
except: sys.exit(0)
u=d.get('usage',{}) or {}
line='%d\t%s\t%s\t%s\t%s\t%s' % (
    int(time.time()), '$pane',
    d.get('total_cost_usd',0),
    u.get('input_tokens',0), u.get('output_tokens',0),
    u.get('cache_read_input_tokens',0))
open('$dir/usage.log','a').write(line+chr(10))
print((d.get('result') or '').strip())
" 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//' | cut -c1-90)
    if [ -n "$summary" ]; then
      printf '%s' "$summary" > "$cache"
      printf '%s' "$newhash" > "$hashf"
    fi
  ) </dev/null >/dev/null 2>&1 &
fi

exit 0
