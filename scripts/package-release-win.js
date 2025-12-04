// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
const fs = require('fs')
const path = require('path')
const os = require('os')
const cp = require('child_process')

function readVersion(root) {
  return fs.readFileSync(path.join(root, 'VERSION'), 'utf8').trim()
}

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true })
}

function copyFile(src, dst) {
  ensureDir(path.dirname(dst))
  fs.copyFileSync(src, dst)
}

function copyDir(src, dst, excludeDirs, excludeExts) {
  ensureDir(dst)
  const entries = fs.readdirSync(src, { withFileTypes: true })
  for (const e of entries) {
    const sp = path.join(src, e.name)
    const dp = path.join(dst, e.name)
    if (e.isDirectory()) {
      if (excludeDirs.includes(e.name)) continue
      copyDir(sp, dp, excludeDirs, excludeExts)
    } else {
      const ext = path.extname(e.name)
      if (excludeExts.includes(ext)) continue
      copyFile(sp, dp)
    }
  }
}

function writeEnvExample(dst) {
  const content = [
    'VITE_API_BASE_URL=http://localhost:10000',
    'BASE_PATH=/api/v1',
    'ALLOWED_ORIGINS=*',
    'JWT_SECRET=change-me',
  ].join('\n')
  fs.writeFileSync(dst, content)
}

function zipDir(srcDir, outZip) {
  try {
    cp.execSync(`zip -r ${JSON.stringify(outZip)} .`, { cwd: srcDir, stdio: 'inherit' })
    return
  } catch (_) {}
  if (process.platform === 'win32') {
    try {
      const ps = `Compress-Archive -Path * -DestinationPath ${JSON.stringify(outZip)} -Force`
      cp.execSync(`powershell -NoProfile -Command ${JSON.stringify(ps)}`, { cwd: srcDir, stdio: 'inherit' })
      return
    } catch (_) {}
  }
  const py = `import os, zipfile
from pathlib import Path
root = Path(${JSON.stringify(srcDir)})
out = Path(${JSON.stringify(outZip)})
with zipfile.ZipFile(out, 'w', compression=zipfile.ZIP_DEFLATED) as z:
  for p in root.rglob('*'):
    z.write(p, p.relative_to(root).as_posix())
print(out)
`
  cp.execSync(`python3 - <<'PY'\n${py}\nPY`, { stdio: 'inherit' })
}

function main() {
  const root = path.resolve(path.join(__dirname, '..'))
  const version = readVersion(root)
  const outDir = path.join(root, 'dist', 'releases')
  const outName = `scaffold-windows-v${version}.zip`
  ensureDir(outDir)
  const stage = fs.mkdtempSync(path.join(os.tmpdir(), 'scaffold-stage-'))
  copyDir(path.join(root, 'frontend'), path.join(stage, 'frontend'), ['node_modules', 'dist', '.cache', '.git'], ['.sh'])
  copyDir(path.join(root, 'backend-node'), path.join(stage, 'backend-node'), ['node_modules', 'dist', '.cache', '.git'], ['.sh'])
  ensureDir(path.join(stage, 'scripts'))
  copyFile(path.join(root, 'scripts', 'pretty.ps1'), path.join(stage, 'scripts', 'pretty.ps1'))
  copyFile(path.join(root, 'scripts', 'install.ps1'), path.join(stage, 'scripts', 'install.ps1'))
  copyFile(path.join(root, 'scripts', 'release.ps1'), path.join(stage, 'scripts', 'release.ps1'))
  copyFile(path.join(root, 'README.md'), path.join(stage, 'README.md'))
  copyFile(path.join(root, 'VERSION'), path.join(stage, 'VERSION'))
  writeEnvExample(path.join(stage, '.env.example'))
  const outZip = path.join(outDir, outName)
  if (fs.existsSync(outZip)) fs.unlinkSync(outZip)
  zipDir(stage, outZip)
  process.stdout.write(`package written: ${outZip}\n`)
}

main()
