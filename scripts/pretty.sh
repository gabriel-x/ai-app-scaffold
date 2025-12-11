#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)

# Simple pretty printing functions to replace missing pretty.sh

p_banner() {
    echo "==== $1 ===="
}

p_ok() {
    echo "[OK] $1"
}

p_err() {
    echo "[ERROR] $1" >&2
}

p_warn() {
    echo "[WARN] $1"
}

p_info() {
    echo "[INFO] $1"
}

p_kv() {
    echo "$1: $2"
}