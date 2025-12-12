# Feature Specification: preflight-check-license

## 1. Overview
**Summary**: 实现preflight check功能，包括代码质量检查和License header检查修复，确保所有代码文件都包含正确的License header。
**Rationale**: 提高代码质量，确保所有代码文件都符合项目License要求，避免法律风险。

## 2. User Scenarios (User Stories)
> Describe how the user interacts with the feature.

- **Scenario 1**: 开发者在提交代码前运行preflight check
  - **Input**: 运行命令 `npm run preflight`
  - **Output**: 检查结果，包括代码质量问题和License header缺失情况
  - **Constraint**: 所有检查必须通过才能提交代码

- **Scenario 2**: 开发者修复License header缺失问题
  - **Input**: 运行命令 `npm run license:fix`
  - **Output**: 自动为缺失License header的文件添加正确的header
  - **Constraint**: 只修复符合条件的文件

## 3. Interface Contract (Technical Spec)
> Define the technical implementation details.

### npm Scripts
- `npm run preflight`: 运行完整的preflight检查，包括：
  - 代码格式化检查
  - 代码质量检查
  - License header检查
  - 类型检查
  - 测试用例运行

- `npm run license:check`: 只运行License header检查

- `npm run license:fix`: 修复缺失License header的文件

### License Header Format
```
// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
```

### Supported File Types
- TypeScript (.ts, .tsx)
- JavaScript (.js, .jsx)

## 4. Acceptance Criteria
- [ ] 运行 `npm run preflight` 能检测到License header缺失的文件
- [ ] 运行 `npm run license:fix` 能自动为缺失License header的文件添加正确的header
- [ ] 所有检查通过后才能提交代码
- [ ] 支持TypeScript和JavaScript文件
- [ ] License header格式与现有文件一致
- [ ] 不影响现有功能正常运行
