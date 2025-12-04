#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node "$ROOT/scripts/package-release-win.js"
