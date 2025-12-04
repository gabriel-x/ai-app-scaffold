#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
set -euo pipefail
cmd=${1:-help}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
source "$ROOT/scripts/pretty.sh" 2>/dev/null || true

backend_cmd() { "$ROOT/backend-node/scripts/server-manager.sh" "$1"; }
frontend_cmd() { "$ROOT/frontend/scripts/client-manager.sh" "$1"; }

start_all() {
  p_banner "Start All (release)"
  backend_cmd start &
  frontend_cmd start &
  wait || true
  p_ok "started. use 'health' or 'status' to check"
}

stop_all() {
  p_banner "Stop All"
  backend_cmd stop || true
  frontend_cmd stop || true
  p_warn "all stopped"
}

status_all() {
  p_banner "Status"
  p_info "backend:"; backend_cmd status || true
  p_info "frontend:"; frontend_cmd status || true
}

logs_all() {
  p_banner "Logs (tail)"
  p_info "backend:"; ( "$ROOT/backend-node/scripts/server-manager.sh" logs ) &
  p_info "frontend:"; ( "$ROOT/frontend/scripts/client-manager.sh" logs ) &
  wait
}

health_all() {
  p_banner "Health"
  p_info "backend:"; backend_cmd health || true
  p_info "frontend:"; frontend_cmd health || true
}

start_dev() {
  p_banner "Start All (dev)"
  backend_cmd start:dev &
  frontend_cmd start:dev &
  wait || true
}

case "$cmd" in
  start) start_all ;;
  stop) stop_all ;;
  status) status_all ;;
  logs) logs_all ;;
  health) health_all ;;
  start:dev) start_dev ;;
  *) p_usage "$0" "start" "stop" "status" "logs" "health" "start:dev" ;;
esac

