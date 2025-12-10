# TRAE 项目专有规则

## 1. 通用规则
- **服务管理**：项目内所有服务均需通过服务管理脚本进行管理，包括启动、停止、重启、监控等操作。
前端服务管理脚本位于 `frontend/scripts/client-manager.sh`。
后端服务管理脚本位于 `backend/scripts/server-manager.sh`。
- **日志管理**：项目内所有服务的日志均需统一管理，包括日志文件路径、日志级别、日志格式等。
前端日志文件路径：`frontend/logs/`
后端日志文件路径：`backend/logs/`
日志级别：`INFO`、`DEBUG`、`ERROR`等
日志格式：`[时间] [服务名] [日志级别] [日志内容]`

## 2. SDD (Spec-Driven Development) 强制约束
- **原则**：**No Spec, No Code.** 禁止在没有对应的 `docs-framework/changes/<feature>/spec.md` 的情况下编写任何功能代码。
- **流程**：
  1. 运行 `./scripts/sdd new <feature>` 创建变更提案。
  2. 填写 `spec.md` 并运行 `./scripts/sdd check <feature> plan` 通过验证。
  3. 生成 `plan.md` 并运行 `./scripts/sdd check <feature> implement` 通过验证。
  4. 开始编码，Git pre-commit 钩子将强制检查此流程。
  5. 完成后运行 `./scripts/sdd archive <feature>` 进行归档。
- **违规阻断**：只要检测到不符合 SDD 原则或流程的操作（如跳过 Spec 直接编码、Spec 内容为空等），必须立即**阻塞**进一步的执行（如拒绝 Commit、停止代码生成），并向用户返回 SDD 标准流程提示，直到合规为止。
