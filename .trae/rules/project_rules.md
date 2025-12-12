# TRAE 项目专有规则

## 1. 通用规则
- **服务管理**：项目所有服务必须通过服务管理脚本管理（启动、停止、重启、监控等）。
  - 前端：`/frontend/scripts/client-manager.sh`
  - 后端：`/backend-node/scripts/server-manager.sh`
  - Python后端：`/backend-python/scripts/server-manager.sh`
- **日志管理**：所有服务日志统一管理。
  - 前端日志：`/frontend/logs/`
  - 后端日志：`/backend-node/logs/`
  - Python后端日志：`/backend-python/logs/`
  - 日志级别：`INFO`、`DEBUG`、`ERROR`等
  - 日志格式：`[时间] [服务名] [日志级别] [日志内容]`

## 2. SDD (Spec-Driven Development) 强制约束
- **核心原则**: **No Spec, No Code.** 禁止无对应 `/docs-framework/changes/<feature>/spec.md` 编写功能代码。
- **解读**: 凡可能导致功能变化的任务都视为变更，必须遵守SDD约束；不确定的情形一律按变更处理。
- **执行流程**：
  1. 运行 `/scripts/sdd new <feature>` 创建变更提案
  2. 填写 `spec.md` 并通过 `/scripts/sdd check <feature> plan` 验证
  3. 生成 `plan.md` 并通过 `/scripts/sdd check <feature> implement` 验证
  4. 开始编码（Git pre-commit 钩子强制检查）
  5. 完成后运行 `/scripts/sdd archive <feature>` 归档
- **违规处理**：任何违反SDD原则或流程的操作（如跳过Spec直接编码、Spec内容为空等）必须立即阻塞执行，返回标准流程提示直至合规。
