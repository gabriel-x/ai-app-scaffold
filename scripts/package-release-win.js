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

function copyDir(src, dst, excludeDirs, excludeExts, excludeFiles) {
  ensureDir(dst)
  const entries = fs.readdirSync(src, { withFileTypes: true })
  for (const e of entries) {
    const sp = path.join(src, e.name)
    const dp = path.join(dst, e.name)
    if (e.isDirectory()) {
      if (excludeDirs.includes(e.name)) continue
      copyDir(sp, dp, excludeDirs, excludeExts, excludeFiles)
    } else {
      const ext = path.extname(e.name)
      if (excludeExts.includes(ext)) continue
      if (excludeFiles.includes(e.name)) continue
      // 排除匹配特定模式的文件，如*.port、*.pid等
      if (e.name.endsWith('.port') || e.name.endsWith('.pid')) continue
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
  const outName = `scaffold-windows-${version}.zip`
  ensureDir(outDir)
  const stage = fs.mkdtempSync(path.join(os.tmpdir(), 'scaffold-stage-'))
  
  // Copy main directories with enhanced exclusions
  const commonExcludeDirs = ['.git', '.vscode', '.idea', 'node_modules', 'dist', '.cache', 'logs', '.trae/documents', '__pycache__', '.pytest_cache', '.vite', 'playwright-report', 'test-results', 'venv', '.venv', '.mypy_cache', '.tox', '.ropeproject']
  const commonExcludeFiles = ['.DS_Store', 'Thumbs.db', 'npm-debug.log*', 'yarn-debug.log*', 'yarn-error.log*', 'pnpm-debug.log*', '*.pyc', '*.pyo', '.python-version', 'debug*.log']
  const backendExcludeDirs = commonExcludeDirs.filter(d => d !== 'dist')
  
  copyDir(path.join(root, 'frontend'), path.join(stage, 'frontend'), commonExcludeDirs, ['.sh'], commonExcludeFiles)
  copyDir(path.join(root, 'backend-node'), path.join(stage, 'backend-node'), backendExcludeDirs, ['.sh'], commonExcludeFiles)
  copyDir(path.join(root, 'backend-python'), path.join(stage, 'backend-python'), commonExcludeDirs, [], commonExcludeFiles)
  copyDir(path.join(root, 'docs-framework'), path.join(stage, 'docs-framework'), commonExcludeDirs, [], commonExcludeFiles)
  copyDir(path.join(root, '.trae', 'rules'), path.join(stage, '.trae', 'rules'), commonExcludeDirs, [], commonExcludeFiles)
  copyDir(path.join(root, 'documents'), path.join(stage, 'documents'), commonExcludeDirs, [], commonExcludeFiles)
  copyDir(path.join(root, 'integration'), path.join(stage, 'integration'), commonExcludeDirs, [], commonExcludeFiles)
  
  // Copy individual files
  copyFile(path.join(root, 'LICENSE'), path.join(stage, 'LICENSE'))
  copyFile(path.join(root, 'NOTICE'), path.join(stage, 'NOTICE'))
  copyFile(path.join(root, 'README.md'), path.join(stage, 'README.md'))
  copyFile(path.join(root, 'VERSION'), path.join(stage, 'VERSION'))
  
  // Copy PowerShell scripts
  ensureDir(path.join(stage, 'scripts'))
  copyFile(path.join(root, 'scripts', 'install.ps1'), path.join(stage, 'scripts', 'install.ps1'))
  copyFile(path.join(root, 'scripts', 'sdd.ps1'), path.join(stage, 'scripts', 'sdd.ps1'))
  copyFile(path.join(root, 'scripts', 'service.ps1'), path.join(stage, 'scripts', 'service.ps1'))
  copyFile(path.join(root, 'scripts', 'package-release-win.ps1'), path.join(stage, 'scripts', 'package-release-win.ps1'))
  
  writeEnvExample(path.join(stage, '.env.example'))
  const outZip = path.join(outDir, outName)
  if (fs.existsSync(outZip)) fs.unlinkSync(outZip)
  zipDir(stage, outZip)
  process.stdout.write(`package written: ${outZip}\n`)
}

main()
