#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
set -euo pipefail
cmd=${1:-help}
source "$(cd "$(dirname "$0")/.." && pwd)/../scripts/pretty.sh" 2>/dev/null || true
ROOT=$(cd "$(dirname "$0")/.." && pwd)
LOG_DIR="$ROOT/logs"
PID_FILE="$LOG_DIR/frontend.pid"
PORT_FILE="$ROOT/.frontend.port"
DEFAULT_RANGE="10100-10190"
mkdir -p "$LOG_DIR"
load_env() {
  if [ -f "$ROOT/.env" ]; then export $(grep -v '^#' "$ROOT/.env" | xargs); fi
  if [ -f "$ROOT/.env.local" ]; then export $(grep -v '^#' "$ROOT/.env.local" | xargs); fi
}
free_port_in_range() {
  IFS='-' read -r start end <<< "${FRONTEND_PORT_RANGE:-$DEFAULT_RANGE}"
  for p in $(seq "$start" "$end"); do
    if ! lsof -i tcp:"$p" >/dev/null 2>&1; then echo "$p"; return 0; fi
  done
  echo ""; return 1
}
ensure_port() {
  if [ -f "$PORT_FILE" ]; then PORT=$(cat "$PORT_FILE"); else PORT=""; fi
  if [ -z "${PORT:-}" ]; then PORT=$(free_port_in_range || true); fi
  if [ -z "${PORT:-}" ]; then PORT=10100; fi
  echo "$PORT" > "$PORT_FILE"
  export PORT
}
start() {
  load_env
  ensure_port
  p_banner "Frontend (preview)"
  p_kv "PORT" "$PORT"
  p_info "building..."
  npm run build > "$LOG_DIR/build.log" 2>&1 || true
  p_info "starting preview..."
  nohup npm run preview -- --port "$PORT" --strictPort > "$LOG_DIR/frontend.log" 2>&1 &
  echo $! > "$PID_FILE"
  p_ok "preview started on http://localhost:$PORT"
}
start_dev() {
  load_env
  ensure_port
  p_banner "Frontend (dev)"
  p_kv "PORT" "$PORT"
  p_info "starting dev server..."
  nohup npm run dev -- --port "$PORT" --strictPort > "$LOG_DIR/frontend.log" 2>&1 &
  echo $! > "$PID_FILE"
  p_ok "dev started on http://localhost:$PORT"
}
stop() {
  if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    kill "$PID" 2>/dev/null || true
    rm -f "$PID_FILE"
  fi
  if [ -f "$PORT_FILE" ]; then
    PORT=$(cat "$PORT_FILE")
    PIDS=$(lsof -ti tcp:"$PORT" || true)
    if [ -n "$PIDS" ]; then kill -9 $PIDS 2>/dev/null || true; fi
  fi
  p_warn "frontend stopped"
}
status() {
  S="stopped"
  if [ -f "$PID_FILE" ]; then PID=$(cat "$PID_FILE"); if ps -p "$PID" >/dev/null 2>&1; then S="running(pid:$PID)"; fi; fi
  if [ -f "$PORT_FILE" ]; then PORT=$(cat "$PORT_FILE"); if lsof -i tcp:"$PORT" >/dev/null 2>&1; then p_kv "port" "$PORT (open)"; fi; fi
  p_info "$S"
}
restart() { stop; start; }
logs() { p_banner "Frontend Logs"; tail -n 100 -f "$LOG_DIR/frontend.log"; }
health() { if [ -f "$PORT_FILE" ]; then curl -s -o /dev/null -w "%{http_code}\n" "http://localhost:$(cat "$PORT_FILE")"; else echo "no-port"; fi }
case "$cmd" in
  start) start ;;
  stop) stop ;;
  restart) restart ;;
  status) status ;;
  logs) logs ;;
  health) health ;;
  start:dev) start_dev ;;
  *) echo "usage: client-manager.sh [start|start:dev|stop|restart|status|logs|health]" ;;
esac
