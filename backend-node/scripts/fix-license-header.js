#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const LICENSE_HEADER = [
  '// SPDX-License-Identifier: MIT',
  '// Copyright (c) 2025 Gabriel Xia(加百列)',
  ''
].join('\n');

const SUPPORTED_EXTENSIONS = ['.ts', '.tsx', '.js', '.jsx'];

function normalizeLineEndings(str) {
  return str.replace(/\r\n/g, '\n');
}

function fixLicenseHeader(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const normalizedContent = normalizeLineEndings(content);
    
    // Check if file already has the exact license header
    if (normalizedContent.startsWith(LICENSE_HEADER)) {
      console.log(`✓ ${filePath}: License header already exists`);
      return true;
    }
    
    // Check if file has any license header (starts with SPDX)
    if (normalizedContent.match(/^\/\/ SPDX-License-Identifier:/m)) {
      // Remove existing license header(s)
      const contentWithoutLicense = normalizedContent
        .replace(/^\/\/ SPDX-License-Identifier:.*?\n(\/\/ Copyright.*?\n)*\s*/m, '');
      
      // Add correct license header
      const newContent = LICENSE_HEADER + contentWithoutLicense;
      fs.writeFileSync(filePath, newContent, 'utf8');
      console.log(`✓ ${filePath}: Fixed existing license header`);
      return true;
    }
    
    // No license header found, add one
    const newContent = LICENSE_HEADER + content;
    fs.writeFileSync(filePath, newContent, 'utf8');
    console.log(`✓ ${filePath}: Added license header`);
    return true;
  } catch (error) {
    console.error(`✗ ${filePath}: Error: ${error.message}`);
    return false;
  }
}

function checkLicenseHeader(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const normalizedContent = normalizeLineEndings(content);
    
    // Check if file has the correct license header
    if (normalizedContent.startsWith(LICENSE_HEADER)) {
      return true;
    }
    
    console.log(`✗ ${filePath}: Missing or incorrect license header`);
    return false;
  } catch (error) {
    console.error(`✗ ${filePath}: Error: ${error.message}`);
    return false;
  }
}

function processDirectory(directoryPath, checkOnly = false) {
  let passed = 0;
  let failed = 0;
  
  function processFile(filePath) {
    if (SUPPORTED_EXTENSIONS.includes(path.extname(filePath))) {
      const result = checkOnly ? checkLicenseHeader(filePath) : fixLicenseHeader(filePath);
      if (result) {
        passed++;
      } else {
        failed++;
      }
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
  
  console.log(`\n=== Summary ===`);
  console.log(`Files checked: ${passed + failed}`);
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);
  
  return failed === 0;
}

const args = process.argv.slice(2);
const checkOnly = args.includes('--check');
const directoryArg = args.find(arg => !arg.startsWith('--'));
const directory = directoryArg || 'src';

console.log(`Processing directory: ${directory}`);
console.log(checkOnly ? 'Mode: Check only' : 'Mode: Fix missing headers');
console.log('Supported extensions:', SUPPORTED_EXTENSIONS.join(', '));
console.log('');

const success = processDirectory(directory, checkOnly);
process.exit(success ? 0 : 1);
