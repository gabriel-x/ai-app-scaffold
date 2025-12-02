# Python 后端库（FastAPI）

- 端点遵循 `scaffold/docs-framework/specs/api/api.yaml` 合同。
- 环境变量：`PORT`、`BASE_PATH`、`ALLOWED_ORIGINS`、`JWT_SECRET`。
- 运行：`uvicorn app.main:app --port $PORT`。
- 健康检查：`GET /health`。
 
## 服务管理脚本
`scripts/server-manager.sh|ps1` 支持 `start/stop/restart/status/logs/health` 与动态端口分配（范围可配 `BACKEND_PORT_RANGE`）。

