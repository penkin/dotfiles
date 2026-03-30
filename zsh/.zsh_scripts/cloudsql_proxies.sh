##############################################
# Cloud SQL Proxy Helpers
###############################################

# Where you keep the proxy binary (adjust if needed)
export CLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Clients/Harambee/Cloud"
export PATH="$PATH:$CLOUD_DIR"

hcloud_kill_all() {
  local pids remaining

  # Match anything with 'cloud-sql' in the command:
  pids=$(pgrep -f "cloud-sql" 2>/dev/null || true)

  if [[ -z "$pids" ]]; then
    echo "[INFO] No cloud SQL proxy processes running."
    return 0
  fi

  echo "[INFO] Killing all cloud SQL proxy processes (SIGTERM): ${pids}"

  # First try as current user
  kill $pids 2>/dev/null || true

  # If any survive, try sudo kill
  sleep 0.3
  remaining=$(pgrep -f "cloud-sql" 2>/dev/null || true)
  if [[ -n "$remaining" ]]; then
    echo "[WARN] Some proxies survived SIGTERM, retrying with sudo kill: ${remaining}"
    sudo kill $remaining 2>/dev/null || true
  fi

  # Check again
  sleep 0.5
  remaining=$(pgrep -f "cloud-sql" 2>/dev/null || true)
  if [[ -n "$remaining" ]]; then
    echo "[WARN] Proxies still running, sending SIGKILL: ${remaining}"
    kill -9 $remaining 2>/dev/null || true

    sleep 0.3
    remaining=$(pgrep -f "cloud-sql" 2>/dev/null || true)
    if [[ -n "$remaining" ]]; then
      echo "[WARN] SIGKILL without sudo failed, retrying with sudo kill -9: ${remaining}"
      sudo kill -9 $remaining 2>/dev/null || true
    fi
  fi

  # Final check
  sleep 0.3
  if pgrep -f "cloud-sql" >/dev/null 2>&1; then
    echo "[ERROR] Some cloud SQL proxy processes are STILL running:"
    pgrep -af "cloud-sql"
    return 1
  else
    echo "[INFO] All cloud SQL proxy processes terminated."
  fi
}

alias cloud-kill-all='hcloud_kill_all'


# ---- Internal helpers ----

_hcloud_kill_proxy_on_port() {
  local port="$1"
  local pids

  # Any process listening on this port
  pids=$(lsof -t -nP -iTCP:"${port}" -sTCP:LISTEN 2>/dev/null || true)

  if [[ -z "$pids" ]]; then
    echo "[INFO] No process listening on port ${port}."
    return 0
  fi

  echo "[INFO] Killing processes on port ${port}: ${pids}"
  kill $pids 2>/dev/null || true

  sleep 0.3
  pids=$(lsof -t -nP -iTCP:"${port}" -sTCP:LISTEN 2>/dev/null || true)
  if [[ -n "$pids" ]]; then
    echo "[WARN] Port ${port} still in use, retrying with sudo kill: ${pids}"
    sudo kill $pids 2>/dev/null || true
  fi

  sleep 0.3
  pids=$(lsof -t -nP -iTCP:"${port}" -sTCP:LISTEN 2>/dev/null || true)
  if [[ -n "$pids" ]]; then
    echo "[WARN] Force killing processes on port ${port} with sudo kill -9: ${pids}"
    sudo kill -9 $pids 2>/dev/null || true
  fi

  if lsof -t -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "[ERROR] Port ${port} is STILL in use:"
    lsof -nP -iTCP:"${port}" -sTCP:LISTEN
    return 1
  else
    echo "[INFO] Port ${port} is now free."
  fi
}



_hcloud_proxy_port() {
  case "$1" in
    dev|dev-adhoc|prod) echo 3310 ;;
    qa)                 echo 3320 ;;
    uat)                echo 3330 ;;
    aux)                echo 3322 ;;
    *)                  echo "" ;;
  esac
}

_hcloud_name_from_instance() {
  local inst="$1"
  case "$inst" in
    *harambee-core-dev)          echo "dev" ;;
    *harambee-adhoc-dev)         echo "dev-adhoc" ;;
    *harambee-core-qa)           echo "qa" ;;
    *harambee-core-v8-4)         echo "uat" ;;
    *harambee-core-v8-3-replica) echo "prod" ;;
    *harambee-aux-dev)           echo "aux" ;;
    *)                           echo "unknown" ;;
  esac
}

_hcloud_start_proxy() {
  local name="$1"
  local instance="$2"
  local port="$3"
  local auto_iam="$4"
  local mode="${HCLOUD_PROXY_MODE:-bg}"      # bg (default) or fg
  local log_file="/tmp/cloud-sql-proxy-${name}.log"
  local iam_flag=""

  if [[ "$auto_iam" == "true" ]]; then
    iam_flag="--auto-iam-authn"
  fi

 if [[ ! -d "$CLOUD_DIR" ]]; then
    echo "[ERROR] CLOUD_DIR '$CLOUD_DIR' does not exist."
    return 1
  fi

  cd "$CLOUD_DIR" || return 1

  # Kill any existing proxy on that port first
  if [[ -n "$port" ]]; then
    _hcloud_kill_proxy_on_port "$port"
  fi

  echo "[INFO] Starting ${name} → ${instance} on port ${port:-default}"
  echo "[INFO] Log file: ${log_file}"

  local port_flag=""
  if [[ -n "$port" ]]; then
    port_flag="--port=${port}"
  fi

  if [[ "$mode" = "fg" ]]; then
    echo "[INFO] Running in foreground. Ctrl+C to stop."
    cloud-sql-proxy $iam_flag "${instance}" $port_flag 2>&1 | tee "${log_file}"
  else
    nohup cloud-sql-proxy $iam_flag "${instance}" $port_flag \
      >> "${log_file}" 2>&1 &

    local pid=$!
    disown "${pid}" 2>/dev/null || true
    echo "[INFO] Started cloud-sql-proxy as PID ${pid}"
  fi
}

hcloud_db_status() {
  local lines

  # Grab all processes with 'cloud-sql' in the command (proxy binary)
  lines=$(ps ax -o pid=,command= | grep -E 'cloud-sql' | grep -v grep || true)

  if [[ -z "$lines" ]]; then
    echo "[INFO] No cloud SQL proxy processes running."
    return 0
  fi

  echo "[INFO] Active cloud SQL proxy processes:"
  printf "%-12s %-8s %-8s %-45s %s\n" "NAME" "PID" "PORT" "INSTANCE" "LOG"
  printf "%-12s %-8s %-8s %-45s %s\n" "------------" "--------" "--------" "---------------------------------------------" "---"

  echo "$lines" | while read -r pid cmd; do
    instance=$(echo "$cmd" | awk '{print $2}')

    port=$(echo "$cmd" | sed -E 's/.*--port="?([0-9]+)"?.*/\1/')
    [[ -z "$port" || "$port" == "$cmd" ]] && port="(n/a)"

    local name
    name=$(_hcloud_name_from_instance "$instance")
    local log_file="/tmp/cloud-sql-proxy-${name}.log"
    local log_indicator="--"
    [[ -f "$log_file" ]] && log_indicator="$log_file"

    printf "%-12s %-8s %-8s %-45s %s\n" "$name" "$pid" "$port" "$instance" "$log_indicator"
  done
}

# Nice short alias
alias hcloud-db-status='hcloud_db_status'

hcloud_db_stop() {
  local name="$1"

  if [[ -n "$name" ]]; then
    local port
    port=$(_hcloud_proxy_port "$name")
    if [[ -z "$port" ]]; then
      echo "[ERROR] Unknown proxy name: $name"
      return 1
    fi
    _hcloud_kill_proxy_on_port "$port"
    return
  fi

  # No argument — interactive fzf selection
  local lines
  lines=$(ps ax -o pid=,command= | grep -E 'cloud-sql' | grep -v grep || true)

  if [[ -z "$lines" ]]; then
    echo "[INFO] No cloud SQL proxy processes running."
    return 0
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    echo "[ERROR] fzf is not installed. Pass a proxy name as argument or install fzf."
    return 1
  fi

  local entries=()
  while read -r pid cmd; do
    local inst port_val pname
    inst=$(echo "$cmd" | awk '{print $2}')
    port_val=$(echo "$cmd" | sed -E 's/.*--port="?([0-9]+)"?.*/\1/')
    [[ -z "$port_val" || "$port_val" == "$cmd" ]] && port_val="(n/a)"
    pname=$(_hcloud_name_from_instance "$inst")
    entries+=("$(printf "%-12s  PID %-8s  PORT %-6s  %s" "$pname" "$pid" "$port_val" "$inst")")
  done <<< "$lines"

  local choice
  choice=$(printf '%s\n' "${entries[@]}" | fzf --prompt="Stop which proxy? > " --height=80% --reverse) || return 1

  local selected_pid
  selected_pid=$(echo "$choice" | sed -E 's/.*PID ([0-9]+).*/\1/')

  if [[ -n "$selected_pid" ]]; then
    echo "[INFO] Killing proxy PID $selected_pid..."
    kill "$selected_pid" 2>/dev/null || sudo kill "$selected_pid" 2>/dev/null || true
    sleep 0.3
    if kill -0 "$selected_pid" 2>/dev/null; then
      echo "[WARN] Process still running, sending SIGKILL..."
      kill -9 "$selected_pid" 2>/dev/null || sudo kill -9 "$selected_pid" 2>/dev/null || true
    fi
    echo "[INFO] Done."
  fi
}

alias hcloud-db-stop='hcloud_db_stop'

hcloud_db_logs() {
  local name="$1"

  if [[ -n "$name" ]]; then
    local log_file="/tmp/cloud-sql-proxy-${name}.log"
    if [[ ! -f "$log_file" ]]; then
      echo "[ERROR] Log file not found: $log_file"
      return 1
    fi
    echo "[INFO] Tailing $log_file (Ctrl+C to stop)"
    tail -f "$log_file"
    return
  fi

  # No argument — interactive fzf selection
  local log_files=(/tmp/cloud-sql-proxy-*.log(N))

  if [[ ${#log_files[@]} -eq 0 ]]; then
    echo "[INFO] No cloud SQL proxy log files found."
    return 0
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    echo "[ERROR] fzf is not installed. Pass a proxy name as argument or install fzf."
    return 1
  fi

  local running_pids
  running_pids=$(ps ax -o command= | grep -E 'cloud-sql' | grep -v grep || true)

  local entries=()
  for lf in "${log_files[@]}"; do
    local base
    base=$(basename "$lf" .log)
    local pname="${base#cloud-sql-proxy-}"
    local marker="[STOPPED]"

    if echo "$running_pids" | grep -q "$pname"; then
      marker="[RUNNING]"
    fi

    entries+=("$(printf "%-10s  %-12s  %s" "$marker" "$pname" "$lf")")
  done

  local choice
  choice=$(printf '%s\n' "${entries[@]}" | fzf --prompt="Tail which log? > " --height=80% --reverse) || return 1

  local selected_file
  selected_file=$(echo "$choice" | awk '{print $NF}')

  if [[ -f "$selected_file" ]]; then
    echo "[INFO] Tailing $selected_file (Ctrl+C to stop)"
    tail -f "$selected_file"
  else
    echo "[ERROR] File not found: $selected_file"
    return 1
  fi
}

alias hcloud-db-logs='hcloud_db_logs'


###############################################
# Database Instance Functions
###############################################

hcloud_db_dev()       { _hcloud_start_proxy "dev"       "harambee-dev:europe-west1:harambee-core-dev"    "3310" "true"; }
hcloud_db_dev_adhoc() { _hcloud_start_proxy "dev-adhoc" "harambee-dev:europe-west1:harambee-adhoc-dev"   "3310" "false"; }
hcloud_db_qa()        { _hcloud_start_proxy "qa"        "harambee-dev:europe-west1:harambee-core-qa"     "3320" "true"; }
hcloud_db_uat()       { _hcloud_start_proxy "uat"       "corestaging:europe-west1:harambee-core-v8-4"    "3330" "true"; }
hcloud_db_prod()      { _hcloud_start_proxy "prod"      "coreproduction:europe-west1:harambee-core-v8-3-replica" "3310" "true"; }
hcloud_db_aux()       { _hcloud_start_proxy "aux"       "harambee-dev:europe-west1:harambee-aux-dev"     "3322" "true"; }

alias hcloud-db-dev='hcloud_db_dev'
alias hcloud-db-dev-adhoc='hcloud_db_dev_adhoc'
alias hcloud-db-qa='hcloud_db_qa'
alias hcloud-db-uat='hcloud_db_uat'
alias hcloud-db-prod='hcloud_db_prod'
alias hcloud-db-aux='hcloud_db_aux'


###############################################
# Help
###############################################

hcloud_db_help() {
  cat <<'EOF'
Cloud SQL Proxy Helper Commands
================================

Start Proxy:
  hcloud-db-dev          Dev core (auto-IAM, port 3310)
  hcloud-db-dev-adhoc    Dev adhoc (port 3310)
  hcloud-db-qa           QA core (auto-IAM, port 3320)
  hcloud-db-uat          UAT core (auto-IAM, port 3330)
  hcloud-db-prod         PROD replica (auto-IAM, port 3310)
  hcloud-db-aux          Aux dev (auto-IAM, port 3322)

  Note: dev, dev-adhoc, and prod share port 3310 — only one at a time.

Manage:
  hcloud-db-stop [name]  Stop a proxy (by name or interactive fzf)
  hcloud-db-logs [name]  Tail proxy logs (by name or interactive fzf)
  hcloud-db-status       Show running proxies (name, pid, port, instance, log)

Global:
  cloud-kill-all         Kill ALL running cloud SQL proxy processes
  hcloud-db-help         Show this help
  hcloud-db              Unified fzf menu (start + manage)

Environment Variables:
  HCLOUD_PROXY_MODE      "bg" (default) or "fg" for foreground mode
  CLOUD_DIR              Path to cloud-sql-proxy binary directory
EOF
}

alias hcloud-db-help='hcloud_db_help'


###############################################
# FZF Menu — Unified Entry Point
###############################################

hcloud-db() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "[ERROR] fzf is not installed. Install it first (e.g. via brew: 'brew install fzf')."
    return 1
  fi

  local choice

  choice=$(
    cat <<'EOF' | fzf --prompt="Cloud SQL Proxy > " --height=80% --reverse
--- Start Proxy ---
start-dev          Dev core (auto-IAM, port 3310)
start-dev-adhoc    Dev adhoc (port 3310)
start-qa           QA core (auto-IAM, port 3320)
start-uat          UAT core (auto-IAM, port 3330)
start-prod         PROD replica (auto-IAM, port 3310)
start-aux          Aux dev (auto-IAM, port 3322)
--- Manage ---
stop               Stop a running proxy (interactive)
logs               Tail proxy logs (interactive)
status             Show running proxies
kill-all           Kill ALL proxy processes
help               Show all commands
EOF
  ) || return 1

  choice=${choice%% *}   # take first field (token)

  case "$choice" in
    start-dev)       hcloud_db_dev ;;
    start-dev-adhoc) hcloud_db_dev_adhoc ;;
    start-qa)        hcloud_db_qa ;;
    start-uat)       hcloud_db_uat ;;
    start-prod)      hcloud_db_prod ;;
    start-aux)       hcloud_db_aux ;;
    stop)            hcloud_db_stop ;;
    logs)            hcloud_db_logs ;;
    status)          hcloud_db_status ;;
    kill-all)        hcloud_kill_all ;;
    help)            hcloud_db_help ;;
    ---*)            ;; # section header selected, ignore
    *)               echo "[WARN] Unknown choice: $choice" ;;
  esac
}
