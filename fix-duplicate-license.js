#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const LICENSE_HEADER = [
  '// SPDX-License-Identifier: MIT',
  '// Copyright (c) 2025 Gabriel Xia(加百列)',
  ''
].join('\n');

const SUPPORTED_EXTENSIONS = ['.ts', '.tsx', '.js', '.jsx'];

function fixDuplicateLicenseHeader(filePath) {
  try {
    let content = fs.readFileSync(filePath, 'utf8');
    
    // Remove all existing license headers
    const contentWithoutLicense = content
      .replace(/^\/\/ SPDX-License-Identifier: MIT\s*\n(\/\/ Copyright \(c\) 2025 Gabriel Xia\(加百列\)\s*\n)+/gm, '')
      .trimStart();
    
    // Add the correct license header
    const newContent = LICENSE_HEADER + contentWithoutLicense;
    
    if (content !== newContent) {
      fs.writeFileSync(filePath, newContent, 'utf8');
      console.log(`✓ ${filePath}: Fixed duplicate license headers`);
      return true;
    } else {
      console.log(`✓ ${filePath}: License header already correct`);
      return false;
    }
  } catch (error) {
    console.error(`✗ ${filePath}: Error: ${error.message}`);
    return false;
  }
}

function processDirectory(directoryPath) {
  function processFile(filePath) {
    if (SUPPORTED_EXTENSIONS.includes(path.extname(filePath))) {
      fixDuplicateLicenseHeader(filePath);
    }
  }
  
  function processDir(dirPath) {
    const entries = fs.readdirSync(dirPath, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dirPath, entry.name);
      if (entry.isDirectory()) {
        processDir(fullPath);
      } else if (entry.isFile()) {
        processFile(fullPath);
      }
    }
  }
  
  processDir(directoryPath);
}

// Process all relevant directories
console.log('Fixing duplicate license headers in backend-node...');
processDirectory('d:\\Dev\\win-scaffold\\backend-node\\src');

console.log('\nFixing duplicate license headers in frontend...');
processDirectory('d:\\Dev\\win-scaffold\\frontend\\src');

console.log('\nAll done!');
