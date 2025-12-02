#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
set -euo pipefail
cmd=${1:-help}
source "$(cd "$(dirname "$0")/.." && pwd)/../scripts/pretty.sh" 2>/dev/null || true
ROOT=$(cd "$(dirname "$0")/.." && pwd)
LOG_DIR="$ROOT/logs"
PID_FILE="$LOG_DIR/backend.pid"
PORT_FILE="$ROOT/.python.port"
DEFAULT_RANGE="10000-10090"
mkdir -p "$LOG_DIR"
load_env() {
  if [ -f "$ROOT/.env" ]; then export $(grep -v '^#' "$ROOT/.env" | xargs); fi
  if [ -f "$ROOT/.env.local" ]; then export $(grep -v '^#' "$ROOT/.env.local" | xargs); fi
}
free_port_in_range() {
  IFS='-' read -r start end <<< "${BACKEND_PORT_RANGE:-$DEFAULT_RANGE}"
  for p in $(seq "$start" "$end"); do
    if ! lsof -i tcp:"$p" >/dev/null 2>&1; then echo "$p"; return 0; fi
  done
  echo ""; return 1
}
ensure_port() {
  if [ -f "$PORT_FILE" ]; then PORT=$(cat "$PORT_FILE"); else PORT=""; fi
  if [ -z "${PORT:-}" ]; then PORT=$(free_port_in_range || true); fi
  if [ -z "${PORT:-}" ]; then PORT=${PORT:-10000}; fi
  echo "$PORT" > "$PORT_FILE"
  export PORT
}
start() {
  load_env
  ensure_port
  p_banner "Python Backend"
  p_kv "PORT" "$PORT"
  p_info "starting uvicorn..."
  nohup uvicorn app.main:app --host 0.0.0.0 --port "$PORT" > "$LOG_DIR/backend.log" 2>&1 &
  echo $! > "$PID_FILE"
  p_ok "started on http://localhost:$PORT"
}
stop() {
  if [ -f "$PID_FILE" ]; then PID=$(cat "$PID_FILE"); kill "$PID" 2>/dev/null || true; rm -f "$PID_FILE"; fi
  if [ -f "$PORT_FILE" ]; then PORT=$(cat "$PORT_FILE"); PIDS=$(lsof -ti tcp:"$PORT" || true); if [ -n "$PIDS" ]; then kill -9 $PIDS 2>/dev/null || true; fi; fi
  p_warn "python backend stopped"
}
status() {
  S="stopped"
  if [ -f "$PID_FILE" ]; then PID=$(cat "$PID_FILE"); if ps -p "$PID" >/dev/null 2>&1; then S="running(pid:$PID)"; fi; fi
  if [ -f "$PORT_FILE" ]; then PORT=$(cat "$PORT_FILE"); if lsof -i tcp:"$PORT" >/dev/null 2>&1; then p_kv "port" "$PORT (open)"; fi; fi
  p_info "$S"
}
restart() { stop; start; }
logs() { p_banner "Python Backend Logs"; tail -n 100 -f "$LOG_DIR/backend.log"; }
health() { if [ -f "$PORT_FILE" ]; then curl -s -o /dev/null -w "%{http_code}\n" "http://localhost:$(cat "$PORT_FILE")/health"; else echo "no-port"; fi }
case "$cmd" in
  start) start ;;
  stop) stop ;;
  restart) restart ;;
  status) status ;;
  logs) logs ;;
  health) health ;;
  *) echo "usage: server-manager.sh [start|stop|restart|status|logs|health]" ;;
esac
