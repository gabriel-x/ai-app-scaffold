#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
source "$ROOT/scripts/pretty.sh" 2>/dev/null || true

require_cmd() { command -v "$1" >/dev/null 2>&1 || { p_err "$1 not found"; exit 1; }; }
version_ge() { printf '%s\n%s' "$2" "$1" | sort -V | head -n1 | grep -q "^$2$"; }

check_env() {
  require_cmd node
  require_cmd npm
  require_cmd lsof
  require_cmd curl
  NV=$(node -v | sed 's/^v//')
  p_kv "node" "$NV"
  version_ge "$NV" "18.0.0" || { p_err "node >= 18 required"; exit 1; }
  NPMV=$(npm -v)
  p_kv "npm" "$NPMV"
  version_ge "$NPMV" "10.0.0" || p_warn "npm >= 10 recommended"
}

ensure_dirs() {
  mkdir -p "$ROOT/frontend/logs" "$ROOT/backend-node/logs"
}

install_dir() {
  d="$1"
  p_banner "Install $d"
  if [ -f "$d/package-lock.json" ]; then
    (cd "$d" && npm ci --no-audit --no-fund)
  else
    (cd "$d" && npm install --no-audit --no-fund)
  fi
  p_ok "deps installed"
}

rand_secret() {
  if command -v openssl >/dev/null 2>&1; then openssl rand -base64 32; else head -c 32 /dev/urandom | base64; fi
}

ensure_env_backend() {
  f="$ROOT/backend-node/.env"
  if [ ! -f "$f" ]; then
    JWT=$(rand_secret)
    {
      echo "BASE_PATH=/api/v1"
      echo "ALLOWED_ORIGINS=*"
      echo "JWT_SECRET=$JWT"
    } > "$f"
    p_ok "backend-node/.env created"
  else
    p_info "backend-node/.env exists"
  fi
}

ensure_env_frontend() {
  f="$ROOT/frontend/.env"
  if [ ! -f "$f" ]; then
    {
      echo "VITE_API_BASE_URL=http://localhost:10000"
    } > "$f"
    p_ok "frontend/.env created"
  else
    p_info "frontend/.env exists"
  fi
}

p_banner "Install & Setup"
check_env
ensure_dirs
install_dir "$ROOT/backend-node"
install_dir "$ROOT/frontend"
ensure_env_backend
ensure_env_frontend
p_ok "ready. use ./scripts/release.sh start"

