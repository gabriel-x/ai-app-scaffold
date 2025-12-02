#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
set -euo pipefail

cmd=${1:-help}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
source "$ROOT/scripts/pretty.sh" 2>/dev/null || true

start_frontend() { (cd "$ROOT/frontend" && npm run dev); }
start_node() { (cd "$ROOT/backend-node" && npm run dev); }
start_python() { (cd "$ROOT/backend-python" && uvicorn app.main:app --port ${PORT:-8000}); }

case "$cmd" in
  start)
    p_banner "Start All"
    p_info "starting frontend and node backend..."
    start_frontend & start_node & ;;
  start:frontend)
    p_banner "Start Frontend"; start_frontend ;;
  start:node)
    p_banner "Start Node"; start_node ;;
  start:python)
    p_banner "Start Python"; start_python ;;
  *)
    p_usage "$0" "start" "start:frontend" "start:node" "start:python" ;;
esac
