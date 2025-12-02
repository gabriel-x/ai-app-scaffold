# Node.js 后端库（Express+TS）

- 端点遵循 `scaffold/docs-framework/specs/api/api.yaml` 合同。
- 环境变量：`PORT`、`BASE_PATH`、`ALLOWED_ORIGINS`、`JWT_SECRET`。
- 启动：`npm run dev`；生产：`npm run build && npm run start`。
- 健康检查：`GET /health`。
 
## 服务管理脚本
`scripts/server-manager.sh|ps1` 支持 `start/stop/restart/status/logs/health` 与动态端口分配（范围可配 `BACKEND_PORT_RANGE`）。
开发模式请使用 `start:dev`，生产或最小运行使用 `start`（自动先 build 再启动），避免文件监视导致的 ENOSPC。

### Ubuntu 使用前置
- 赋予执行权限：`chmod +x scripts/server-manager.sh`
- 或通过 bash 调用：`bash scripts/server-manager.sh start`
