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
  printf "%-8s %-8s %s\n" "PID" "PORT" "INSTANCE"
  printf "%-8s %-8s %s\n" "--------" "--------" "----------------------------------------"

  echo "$lines" | while read -r pid cmd; do
    # Instance is the 2nd token (after 'cloud-sql[-proxy]')
    instance=$(echo "$cmd" | awk '{print $2}')

    # Port from --port=NNNN (if present)
    port=$(echo "$cmd" | sed -E 's/.*--port="?([0-9]+)"?.*/\1/')
    [[ -z "$port" || "$port" == "$cmd" ]] && port="(n/a)"

    printf "%-8s %-8s %s\n" "$pid" "$port" "$instance"
  done
}

# Nice short alias
alias hcloud-db-status='hcloud_db_status'


###############################################
# Database Instance Functions
###############################################

hcloud_db_dev()       { _hcloud_start_proxy "dev"       "harambee-dev:europe-west1:harambee-core-dev"    "3310" "true"; }
hcloud_db_dev_adhoc() { _hcloud_start_proxy "dev-adhoc" "harambee-dev:europe-west1:harambee-adhoc-dev"   "3310" "false"; }
hcloud_db_qa()        { _hcloud_start_proxy "qa"        "harambee-dev:europe-west1:harambee-core-qa"     "3320" "true"; }
hcloud_db_uat()       { _hcloud_start_proxy "uat"       "corestaging:europe-west1:harambee-core-v8-4"    "3330" "true"; }
hcloud_db_prod()      { _hcloud_start_proxy "prod"      "coreproduction:europe-west1:harambee-core-v8-3-replica" "" "false"; }
hcloud_db_aux()       { _hcloud_start_proxy "aux"       "harambee-dev:europe-west1:harambee-aux-dev"     "3322" "true"; }

alias hcloud-db-dev='hcloud_db_dev'
alias hcloud-db-dev-adhoc='hcloud_db_dev_adhoc'
alias hcloud-db-qa='hcloud_db_qa'
alias hcloud-db-uat='hcloud_db_uat'
alias hcloud-db-prod='hcloud_db_prod'
alias hcloud-db-aux='hcloud_db_aux'


###############################################
# FZF Menu
###############################################
# hcloud-db -> fuzzy menu of all instances
###############################################

hcloud-db() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "[ERROR] fzf is not installed. Install it first (e.g. via brew: 'brew install fzf')."
    return 1
  fi

  local choice

  choice=$(
    cat <<'EOF' | fzf --prompt="Select Cloud SQL instance > " --height=80% --reverse
dev          Dev core (--auto-iam-authn, port 3310)
dev-adhoc    Dev adhoc (port 3310)
qa           QA core (--auto-iam-authn, port 3320)
uat          UAT core (--auto-iam-authn, port 3330)
prod         PROD replica (no port specified)
aux          Aux dev (--auto-iam-authn, port 3322)
EOF
  ) || return 1

  choice=${choice%% *}   # take first field (token)

  case "$choice" in
    dev)       hcloud_db_dev ;;
    dev-adhoc) hcloud_db_dev_adhoc ;;
    qa)        hcloud_db_qa ;;
    uat)       hcloud_db_uat ;;
    prod)      hcloud_db_prod ;;
    aux)       hcloud_db_aux ;;
    *)         echo "[WARN] Unknown choice: $choice" ;;
  esac
}
