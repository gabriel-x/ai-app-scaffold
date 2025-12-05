# Scaffold 总览

- 独立库：`frontend/`、`backend-node/`、`backend-python/`、`docs-framework/`。
- 一致性合同：`docs-framework/specs/api/api.yaml`（OpenAPI 3.1）。
- 集成示例：`integration/docker-compose.yml`；服务脚本：`scripts/service.sh|ps1`。
- 运行变量：前端 `VITE_API_BASE_URL`，后端 `PORT/BASE_PATH/ALLOWED_ORIGINS/JWT_SECRET`。

## 启动与联调

- 后端（Node）：`backend-node/scripts/server-manager.sh start:dev` → `http://localhost:10000`
- 前端：`frontend/scripts/client-manager.sh start:dev` → `http://localhost:10100`
- 前端配置：在 `frontend/.env` 设置 `VITE_API_BASE_URL=http://localhost:10000`

## 发布与一键启动（v1.0.0）

### Linux 发布包制作
- 运行 `./scripts/package-release.sh`
  - 输出：`dist/releases/scaffold-v1.0.0.tar.gz`
  - 内容：`frontend/`、`backend-node/`、`scripts/install.sh|release.sh|pretty.sh`、`README.md`、`VERSION`、`.env.example`

### Linux 下载与解压
- 将 `scaffold-v1.0.0.tar.gz` 下载到目标目录
- 解压：`tar -xzf scaffold-v1.0.0.tar.gz`

### Linux 一键安装与启动
- 一键安装：在包根目录运行 `./scripts/install.sh`（检查环境、安装依赖、创建日志与默认 `.env`）
- 一键启动（生产预览）：`./scripts/release.sh start`
  - 后端端口范围 `10000-10090`（健康检查 `GET /health`）
  - 前端端口范围 `10100-10190`（`vite preview`）
- 健康与日志：`./scripts/release.sh health`；`./scripts/release.sh logs`
- 停止与状态：`./scripts/release.sh stop`；`./scripts/release.sh status`

### Linux 安装脚本说明
- `scripts/install.sh`
  - 依赖：`node>=18`、`npm>=10`、`lsof`、`curl`
  - 生成示例 `.env`
    - `frontend/.env`：`VITE_API_BASE_URL=http://localhost:10000`
    - `backend-node/.env`：`BASE_PATH=/api/v1`、`ALLOWED_ORIGINS=*`、`JWT_SECRET=<随机>`

### Windows 发布包制作
- 推荐：在 Bash 中运行 `./scripts/package-release-win.sh`
  - 输出：`dist/releases/scaffold-windows-v1.0.0.zip`
  - 内容：`frontend/`、`backend-node/`、`scripts/install.ps1|release.ps1|pretty.ps1`、`README.md`、`VERSION`、`.env.example`
- 备选：在 PowerShell 中运行 `pwsh -NoProfile -File scripts/package-release-win.ps1`
  - 两者底层统一使用 `scripts/package-release-win.js` 实现，确保打包逻辑一致

### Windows 下载与解压
- 将 `scaffold-windows-v1.0.0.zip` 下载到目标目录
- 解压（PowerShell）：`Expand-Archive -Path .\scaffold-windows-v1.0.0.zip -DestinationPath .\scaffold-windows-v1.0.0`

### Windows 一键安装与启动
- 一键安装：在包根目录运行 `.\scripts\install.ps1`（检查环境、安装依赖、创建日志与默认 `.env`）
- 一键启动（生产预览）：`.\scripts\release.ps1 start`
  - 后端端口范围 `10000-10090`（健康检查 `GET /health`）
  - 前端端口范围 `10100-10190`（`vite preview`）
- 健康与日志：`.\scripts\release.ps1 health`；`.\scripts\release.ps1 logs`
- 停止与状态：`.\scripts\release.ps1 stop`；`.\scripts\release.ps1 status`

### Windows 安装脚本说明
- `scripts/install.ps1`
  - 依赖：`node>=18`、`npm`
  - 生成示例 `.env`
    - `frontend/.env`：`VITE_API_BASE_URL=http://localhost:10000`
    - `backend-node/.env`：`BASE_PATH=/api/v1`、`ALLOWED_ORIGINS=*`、`JWT_SECRET=<随机>`

### Windows 常见问题与自助排查
- **端口文件解析错误**：若启动失败且日志无明显错误，请检查 `.node.port` 或 `.frontend.port` 文件内容是否包含非数字字符（如 BOM 头或空白行）。现有脚本已增加过滤逻辑，但手动修改时需注意。
- **服务启动参数冲突**：`Start-Process` 在 Windows 上同时使用 `-NoNewWindow` 和 `-WindowStyle Hidden` 会导致错误。请确保使用最新版 `server-manager.ps1`，已移除冲突参数。
- **API 契约验证**：如需验证后端接口是否符合预期，可运行 `powershell -NoProfile -ExecutionPolicy Bypass -File backend-node/scripts/test-api.ps1`。该脚本会执行完整的注册、登录、刷新令牌及个人信息更新流程，并生成 JSON 报告。


### 开发模式（可选）
- 前端：`frontend/scripts/client-manager.sh start:dev`
- 后端：`backend-node/scripts/server-manager.sh start:dev`

> 提示：端口文件位于各模块根目录（`.frontend.port`/`.node.port`），日志在 `frontend/logs/` 与 `backend-node/logs/`。

## 功能演示

- 注册：页面 `/register` 调用 `POST /api/v1/auth/register`
- 登录：页面 `/login` 调用 `POST /api/v1/auth/login`，成功后访问 `GET /api/v1/auth/me`
- 个人页：页面 `/profile` 展示当前用户数据，可更新昵称（调用 `PATCH /api/v1/accounts/profile`）

## 合同（OpenAPI）

- 位置：`docs-framework/specs/api/api.yaml`
- 接口：`/auth/register|login|refresh|me`，`/accounts/profile (GET|PATCH)`，`/health`
## License & Notice

- 主许可证：`LICENSE`（MIT）。
- 版权主体：Gabriel Xia(加百列)。
- 源码文件采用 SPDX 头部标识（`SPDX-License-Identifier: MIT`）与版权声明统一管理。
- 版权声明文件：`NOTICE`；第三方组件许可证信息见各模块包管理清单。
