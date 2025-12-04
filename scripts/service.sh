#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
set -euo pipefail

cmd=${1:-help}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
source "$ROOT/scripts/pretty.sh" 2>/dev/null || true

PID_DIR="$ROOT/scripts/pids"
mkdir -p "$PID_DIR"

FE_DIR="$ROOT/frontend"
NODE_DIR="$ROOT/backend-node"
PY_DIR="$ROOT/backend-python"

FE_CMD="${FE_CMD:-npm run dev}"
NODE_CMD="${NODE_CMD:-npm run dev}"
PY_CMD="${PY_CMD:-uvicorn app.main:app --port ${PORT:-8000}}"

start_service() {
  n=$1; dir=$2; c=$3
  pid_file="$PID_DIR/$n.pid"
  if [ ! -d "$dir" ]; then
    p_err "directory not found: $dir"
    return 1
  fi
  if [ -f "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
    p_warn "$n already running (pid $(cat "$pid_file"))"
    return 0
  fi
  p_info "starting $n..."
  nohup bash -lc "cd \"$dir\" && $c" >/dev/null 2>&1 &
  echo $! > "$pid_file"
  p_ok "$n started (pid $(cat "$pid_file"))"
}

stop_service() {
  n=$1
  pid_file="$PID_DIR/$n.pid"
  if [ ! -f "$pid_file" ]; then
    p_warn "$n not running"
    return 0
  fi
  pid=$(cat "$pid_file")
  if kill -0 "$pid" 2>/dev/null; then
    p_info "stopping $n (pid $pid)..."
    kill "$pid" 2>/dev/null || true
    for i in $(seq 1 20); do
      if kill -0 "$pid" 2>/dev/null; then sleep 0.2; else break; fi
    done
    if kill -0 "$pid" 2>/dev/null; then
      p_warn "$n still running, force kill"
      kill -9 "$pid" 2>/dev/null || true
    fi
    p_ok "$n stopped"
  else
    p_warn "$n not alive"
  fi
  rm -f "$pid_file"
}

status_service() {
  n=$1
  pid_file="$PID_DIR/$n.pid"
  if [ -f "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
    p_kv "$n" "running (pid $(cat \"$pid_file\"))"
  else
    p_kv "$n" "stopped"
  fi
}

restart_service() { n=$1; dir=$2; c=$3; stop_service "$n"; start_service "$n" "$dir" "$c"; }

start_frontend() { start_service frontend "$FE_DIR" "$FE_CMD"; }
stop_frontend() { stop_service frontend; }
status_frontend() { status_service frontend; }
restart_frontend() { restart_service frontend "$FE_DIR" "$FE_CMD"; }

start_node() { start_service node "$NODE_DIR" "$NODE_CMD"; }
stop_node() { stop_service node; }
status_node() { status_service node; }
restart_node() { restart_service node "$NODE_DIR" "$NODE_CMD"; }

start_python() { start_service python "$PY_DIR" "$PY_CMD"; }
stop_python() { stop_service python; }
status_python() { status_service python; }
restart_python() { restart_service python "$PY_DIR" "$PY_CMD"; }

case "$cmd" in
  start)
    p_banner "Start All"
    start_frontend; start_node; start_python ;;
  stop)
    p_banner "Stop All"
    stop_frontend; stop_node; stop_python ;;
  restart)
    p_banner "Restart All"
    restart_frontend; restart_node; restart_python ;;
  status)
    p_banner "Status"
    status_frontend; status_node; status_python ;;
  start:frontend) p_banner "Start Frontend"; start_frontend ;;
  stop:frontend) p_banner "Stop Frontend"; stop_frontend ;;
  restart:frontend) p_banner "Restart Frontend"; restart_frontend ;;
  status:frontend) p_banner "Status Frontend"; status_frontend ;;
  start:node) p_banner "Start Node"; start_node ;;
  stop:node) p_banner "Stop Node"; stop_node ;;
  restart:node) p_banner "Restart Node"; restart_node ;;
  status:node) p_banner "Status Node"; status_node ;;
  start:python) p_banner "Start Python"; start_python ;;
  stop:python) p_banner "Stop Python"; stop_python ;;
  restart:python) p_banner "Restart Python"; restart_python ;;
  status:python) p_banner "Status Python"; status_python ;;
  *)
    p_usage "$0" \
      "start" "stop" "restart" "status" \
      "start:frontend" "stop:frontend" "restart:frontend" "status:frontend" \
      "start:node" "stop:node" "restart:node" "status:node" \
      "start:python" "stop:python" "restart:python" "status:python" ;;
esac
