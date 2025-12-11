#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
source "$ROOT/scripts/pretty.sh" 2>/dev/null || true

VERSION=$(grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+' "$ROOT/VERSION" 2>/dev/null | sed 's/^v//' || echo "1.0.0")
OUT_DIR="$ROOT/dist/releases"
OUT_NAME="scaffold-v$VERSION.tar.gz"

mkdir -p "$OUT_DIR"

p_banner "Package v$VERSION"

# Create temp staging directory
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

copy_safe() {
  src="$1"; dst="$2"; mkdir -p "$dst"; rsync -a --exclude node_modules --exclude dist --exclude .cache --exclude .DS_Store --exclude venv --exclude __pycache__ --exclude .pytest_cache "$src/" "$dst/"
}

# Include frontend, backend-node and backend-python
copy_safe "$ROOT/frontend" "$STAGE/frontend"
copy_safe "$ROOT/backend-node" "$STAGE/backend-node"
copy_safe "$ROOT/backend-python" "$STAGE/backend-python"

# Include scripts
mkdir -p "$STAGE/scripts"
cp "$ROOT/scripts/pretty.sh" "$STAGE/scripts/"
cp "$ROOT/scripts/install.sh" "$STAGE/scripts/"
cp "$ROOT/scripts/service.sh" "$STAGE/scripts/"

# Include top-level docs and version
cp "$ROOT/README.md" "$STAGE/README.md"
cp "$ROOT/VERSION" "$STAGE/VERSION"

# Provide .env.example
cat > "$STAGE/.env.example" <<EOF
# Frontend
VITE_API_BASE_URL=http://localhost:10000

# Backend Node
BASE_PATH=/api/v1
ALLOWED_ORIGINS=*
JWT_SECRET=change-me
EOF

(cd "$STAGE" && tar -czf "$OUT_DIR/$OUT_NAME" .)

p_ok "package written: $OUT_DIR/$OUT_NAME"

