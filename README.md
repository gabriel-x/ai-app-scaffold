# Scaffold 总览

- 独立库：`frontend/`、`backend-node/`、`backend-python/`、`docs-framework/`。
- 一致性合同：`docs-framework/specs/api/api.yaml`（OpenAPI 3.1）。
- 集成示例：`integration/docker-compose.yml`；服务脚本：`scripts/service.sh|ps1`。
- 运行变量：前端 `VITE_API_BASE_URL`，后端 `PORT/BASE_PATH/ALLOWED_ORIGINS/JWT_SECRET`。

