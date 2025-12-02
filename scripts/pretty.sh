#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

p_banner() {
  t=${1:-""}
  echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  if [ -n "$t" ]; then echo -e "${CYAN}${BOLD}  $t${RESET}"; fi
  echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

p_info() { echo -e "${BLUE}ℹ${RESET} $1"; }
p_ok() { echo -e "${GREEN}✓${RESET} $1"; }
p_warn() { echo -e "${YELLOW}⚠${RESET} $1"; }
p_err() { echo -e "${RED}✗${RESET} $1"; }
p_kv() { printf "%b%b%-12s%b %s\n" "$BOLD" "$MAGENTA" "$1:" "$RESET" "$2"; }

p_usage() {
  n=${1:-$0}
  shift || true
  p_banner "Usage"
  echo -e "${BOLD}$n${RESET} [command]"
  echo -e "${CYAN}Commands:${RESET}"
  for c in "$@"; do echo "  • $c"; done
}
