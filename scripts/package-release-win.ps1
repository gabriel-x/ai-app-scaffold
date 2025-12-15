# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
Param()
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
& node (Join-Path $root 'scripts/package-release-win.js') | Write-Host
