# Scaffold 总览

- 独立库：`frontend/`、`backend-node/`、`backend-python/`、`docs-framework/`。
- 一致性合同：`docs-framework/specs/api/api.yaml`（OpenAPI 3.1）。
- 集成示例：`integration/docker-compose.yml`；服务脚本：`scripts/service.sh|ps1`。
- 运行变量：前端 `VITE_API_BASE_URL`，后端 `PORT/BASE_PATH/ALLOWED_ORIGINS/JWT_SECRET`。

## 启动与联调

- 后端（Node）：`backend-node/scripts/server-manager.sh start:dev` → `http://localhost:10000`
- 前端：`frontend/scripts/client-manager.sh start:dev` → `http://localhost:10100`
- 前端配置：在 `frontend/.env` 设置 `VITE_API_BASE_URL=http://localhost:10000`

## 功能演示

- 注册：页面 `/register` 调用 `POST /api/v1/auth/register`
- 登录：页面 `/login` 调用 `POST /api/v1/auth/login`，成功后访问 `GET /api/v1/auth/me`
- 个人页：页面 `/profile` 展示当前用户数据，可更新昵称（调用 `PATCH /api/v1/accounts/profile`）

## 合同（OpenAPI）

- 位置：`docs-framework/specs/api/api.yaml`
- 接口：`/auth/register|login|refresh|me`，`/accounts/profile (GET|PATCH)`，`/health`
