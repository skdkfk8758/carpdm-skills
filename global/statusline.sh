#!/usr/bin/env bash
# Claude Code statusline — optimized for ADMap solo-dev workflow
# Layout: Model │ Project │ Branch● │ ██░░░ 34% │ 5h:12% 7d:3% │ $0.42 │ +128 -45 │ 23m
# Worktree mode: 🌿wt-name replaces branch segment

set -euo pipefail

input=$(cat)

# --- Single jq call for all fields (perf: 1 fork instead of 12+) ---
eval "$(echo "$input" | jq -r '
  @sh "model=\(.model.display_name // "Unknown")",
  @sh "used_pct=\(.context_window.used_percentage // "")",
  @sh "ctx_size=\(.context_window.context_window_size // 0)",
  @sh "total_in=\(.context_window.total_input_tokens // 0)",
  @sh "total_out=\(.context_window.total_output_tokens // 0)",
  @sh "cost=\(.cost.total_cost_usd // "")",
  @sh "duration_ms=\(.cost.total_duration_ms // "")",
  @sh "lines_add=\(.cost.total_lines_added // 0)",
  @sh "lines_del=\(.cost.total_lines_removed // 0)",
  @sh "cwd=\(.workspace.current_dir // "")",
  @sh "project_dir=\(.workspace.project_dir // "")",
  @sh "wt_name=\(.worktree.name // "")",
  @sh "wt_branch=\(.worktree.branch // "")",
  @sh "rl_5h=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "rl_7d=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "transcript=\(.transcript_path // "")"
' 2>/dev/null)" || true

# --- ANSI colors ---
R='\033[0m'    # reset
B='\033[1m'    # bold
D='\033[2m'    # dim
GR='\033[32m'  # green
YL='\033[33m'  # yellow
RD='\033[31m'  # red
CY='\033[36m'  # cyan
MG='\033[35m'  # magenta
BL='\033[34m'  # blue
WH='\033[37m'  # white

SEP="${D} │ ${R}"

# --- Project name (basename of project_dir or cwd) ---
proj_base="${project_dir:-$cwd}"
project="$(basename "${proj_base:-$PWD}")"

# --- Git branch + dirty ---
branch_seg=""
if [ -n "${cwd:-}" ]; then
  git_dir="${cwd}"
  if git -C "$git_dir" rev-parse --is-inside-work-tree &>/dev/null; then
    branch="$(git -C "$git_dir" branch --show-current 2>/dev/null || echo "")"
    dirty=""
    if ! git -C "$git_dir" diff --no-lock-index --quiet HEAD 2>/dev/null || \
       ! git -C "$git_dir" diff --no-lock-index --cached --quiet HEAD 2>/dev/null; then
      dirty="${YL}●${R}"
    fi
    if [ -n "${wt_name:-}" ]; then
      # Worktree mode
      branch_seg="${MG}🌿${wt_name}${R}"
      [ -n "${wt_branch:-}" ] && branch_seg+="${D}(${wt_branch})${R}"
      branch_seg+="${dirty}"
    elif [ -n "$branch" ]; then
      branch_seg="${CY}${branch}${R}${dirty}"
    fi
  fi
fi

# --- Context bar (width=5, compact) ---
ctx_seg=""
if [ -n "${used_pct:-}" ]; then
  pct_int=$(printf "%.0f" "$used_pct" 2>/dev/null || echo "0")
  width=5
  filled=$(( (pct_int * width + 50) / 100 ))
  [ $filled -gt $width ] && filled=$width
  empty=$(( width - filled ))

  if   [ "$pct_int" -lt 60 ]; then clr=$GR
  elif [ "$pct_int" -lt 85 ]; then clr=$YL
  else                              clr=$RD
  fi

  bar=""
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=0; i<empty;  i++ )); do bar+="░"; done
  ctx_seg="${clr}${bar} ${pct_int}%%${R}"
fi

# --- Rate limits ---
rl_seg=""
rl_parts=()
if [ -n "${rl_5h:-}" ]; then
  pct5=$(printf "%.0f" "$rl_5h" 2>/dev/null || echo "0")
  if   [ "$pct5" -lt 60 ]; then c5=$GR
  elif [ "$pct5" -lt 85 ]; then c5=$YL
  else                           c5=$RD
  fi
  rl_parts+=("${D}5h:${R}${c5}${pct5}%%${R}")
fi
if [ -n "${rl_7d:-}" ]; then
  pct7=$(printf "%.0f" "$rl_7d" 2>/dev/null || echo "0")
  if   [ "$pct7" -lt 60 ]; then c7=$GR
  elif [ "$pct7" -lt 85 ]; then c7=$YL
  else                           c7=$RD
  fi
  rl_parts+=("${D}7d:${R}${c7}${pct7}%%${R}")
fi
if [ ${#rl_parts[@]} -gt 0 ]; then
  rl_seg=$(IFS=' '; echo "${rl_parts[*]}")
fi

# --- Cost ---
cost_seg=""
if [ -n "${cost:-}" ] && [ "$cost" != "null" ]; then
  cost_fmt=$(awk "BEGIN { printf \"%.2f\", $cost }" 2>/dev/null || echo "$cost")
  cost_seg="${YL}\$${cost_fmt}${R}"
fi

# --- Lines added/removed (from session stats) ---
lines_seg=""
la="${lines_add:-0}"
ld="${lines_del:-0}"
if [ "$la" -gt 0 ] || [ "$ld" -gt 0 ]; then
  lines_seg="${GR}+${la}${R} ${RD}-${ld}${R}"
fi

# --- Session elapsed time ---
elapsed_seg=""
if [ -n "${duration_ms:-}" ] && [ "$duration_ms" != "null" ] && [ "$duration_ms" -gt 0 ] 2>/dev/null; then
  total_sec=$(( duration_ms / 1000 ))
  h=$(( total_sec / 3600 ))
  m=$(( (total_sec % 3600) / 60 ))
  if [ $h -gt 0 ]; then
    elapsed_seg="${BL}${h}h${m}m${R}"
  else
    elapsed_seg="${BL}${m}m${R}"
  fi
elif [ -n "${transcript:-}" ] && [ -f "$transcript" ]; then
  created=$(stat -f "%SB" -t "%s" "$transcript" 2>/dev/null || stat -c "%Y" "$transcript" 2>/dev/null || echo "")
  if [ -n "$created" ]; then
    now=$(date +%s)
    diff=$(( now - created ))
    h=$(( diff / 3600 ))
    m=$(( (diff % 3600) / 60 ))
    if [ $h -gt 0 ]; then
      elapsed_seg="${BL}${h}h${m}m${R}"
    else
      elapsed_seg="${BL}${m}m${R}"
    fi
  fi
fi

# --- Assemble ---
parts=()
parts+=("${B}${CY}${model}${R}")
parts+=("${WH}${project}${R}")
[ -n "$branch_seg" ]  && parts+=("$branch_seg")
[ -n "$ctx_seg" ]     && parts+=("$ctx_seg")
[ -n "$rl_seg" ]      && parts+=("$rl_seg")
[ -n "$cost_seg" ]    && parts+=("$cost_seg")
[ -n "$lines_seg" ]   && parts+=("$lines_seg")
[ -n "$elapsed_seg" ] && parts+=("$elapsed_seg")

output=""
for i in "${!parts[@]}"; do
  [ $i -gt 0 ] && output+="$SEP"
  output+="${parts[$i]}"
done

printf "$output\n"
