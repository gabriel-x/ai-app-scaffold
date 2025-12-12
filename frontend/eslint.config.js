// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import eslint from '@eslint/js';
import tseslint from '@typescript-eslint/eslint-plugin';
import tsParser from '@typescript-eslint/parser';
import licenseHeader from 'eslint-plugin-license-header';
import * as globals from 'globals';

export default [
  eslint.configs.recommended,
  {
    files: ['src/**/*.{ts,tsx}'],
    languageOptions: {
      parser: tsParser,
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        ...globals.browser,
        localStorage: 'readonly',
        document: 'readonly',
        fetch: 'readonly',
        Headers: 'readonly',
        RequestInit: 'readonly',
        setTimeout: 'readonly',
        HTMLInputElement: 'readonly'
      }
    },
    plugins: {
      '@typescript-eslint': tseslint,
      'license-header': licenseHeader
    },
    rules: {
      ...tseslint.configs.recommended.rules,
      '@typescript-eslint/no-unused-vars': 'warn',
      '@typescript-eslint/no-explicit-any': 'warn'
    }
  }
];
