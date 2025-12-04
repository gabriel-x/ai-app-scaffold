# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
Param()
function Banner($t) {
  Write-Host "============================================================"
  if ($t) { Write-Host "  $t" }
  Write-Host "============================================================"
}
function Info($m) { Write-Host "[i] $m" }
function Ok($m) { Write-Host "[+] $m" }
function Warn($m) { Write-Host "[!] $m" }
function Err($m) { Write-Host "[x] $m" }
function Kv($k,$v) { Write-Host ($k + ":" + $v) }

