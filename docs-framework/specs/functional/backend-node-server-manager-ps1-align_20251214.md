# Feature Specification: backend-node-server-manager-ps1-align

## 1. Overview
**Summary**: 对齐并增强 Windows PowerShell 后端 Node 服务管理脚本 `backend-node/scripts/server-manager.ps1`，使其在开发目录和 Windows 安装包中都能可靠地启动、停止、重启和检查后端服务，并与 Bash 版 `server-manager.sh` 保持一致的端口管理、依赖安装和状态语义。

**Rationale**:
- 当前 Windows 安装包中使用 `server-manager.ps1 start` 时会错误识别其他 node 进程（如前端 Vite），导致标记“启动成功”但实际后端端口未监听，`/health` 返回 404。
- 现有 PowerShell 脚本端口与 PID 检测策略过于宽松，仅通过 node 进程及任意监听端口匹配，缺乏对“本项目进程”和“目标端口”的约束。
- 需要统一 Windows 与 Linux 的服务管理行为，降低用户在 Windows 上启动后端服务的排障成本。

## 2. User Scenarios (User Stories)

- **Scenario 1：Windows 开发者启动后端服务（开发模式）**
  - **Input**: 在仓库根目录或安装包根目录运行 `.\backend-node\scripts\server-manager.ps1 start`
  - **Output**:
    - 如果后端未运行：自动选择或复用合适端口，必要时安装依赖，启动 `pnpm run dev` 或 `npm run dev`，并准确记录后端服务 PID 与监听端口。
    - 如果后端已运行：检测到已有服务，输出提示并避免重复启动。
  - **Constraint**:
    - 依赖 `node`、`npm` 或 `pnpm` 已安装且在 PATH 中。

- **Scenario 2：Windows 开发者检查后端服务状态**
  - **Input**: 在根目录运行 `.\backend-node\scripts\server-manager.ps1 status`
  - **Output**:
    - 若通过 PID 文件确认服务运行：输出 PID 和实际监听端口，并检查端口是否监听。
    - 若 PID 文件缺失但端口上存在本项目后端服务：给出提示并返回成功状态。
    - 若既无 PID 又无端口监听：明确告知后端服务未运行。
  - **Constraint**:
    - 状态结果应与实际监听端口和进程一致，不受其他无关 node 进程干扰。

- **Scenario 3：Windows 用户从安装包中启动后端服务并访问健康检查**
  - **Input**:
    - 解压 Windows 安装包到任意目录；
    - 运行 `.\backend-node\scripts\server-manager.ps1 start` 启动后端；
    - 通过浏览器或 curl 访问 `http://localhost:<port>/health`。
  - **Output**:
    - `start` 能正确启动后端；
    - `/health` 接口返回 200 且非 404；
    - `status` 报告结果与真实运行状态一致。
  - **Constraint**:
    - 不依赖源码目录；所有行为基于安装包内容。

## 3. Interface Contract (脚本接口约定)

本变更不修改 HTTP API，而是改进后端服务管理脚本的命令接口及行为约束。

### Endpoints
- `.\backend-node\scripts\server-manager.ps1 start`
  - 行为：按 `.env` 和默认配置选择端口，若无依赖则安装，在后台启动 dev 服务，记录 PID 到 `.node.pid`，并输出访问地址。

- `.\backend-node\scripts\server-manager.ps1 stop`
  - 行为：优先根据 PID 文件停止后端服务；若 PID 失效，但目标端口仍被本项目进程占用，则基于命令行与工作目录安全清理残留进程。

- `.\backend-node\scripts\server-manager.ps1 status`
  - 行为：基于 PID 文件与端口监听状态综合判断服务是否运行，并输出健康状态信息。

- `.\backend-node\scripts\server-manager.ps1 logs`
  - 行为：输出 `backend-node/logs/backend.log` 的最后若干行。

## 4. Acceptance Criteria
- [ ] 使用 `server-manager.ps1 start` 后，后端真实在某个端口监听（默认 10000），且 `status` 报告的 PID 和端口与 `netstat` 结果一致。
- [ ] 在 Windows 安装包中运行 `start` 后，通过浏览器或 curl 访问 `/health` 返回 200，不再出现 404。
- [ ] `status` 在服务未运行时返回明确的错误信息与非零退出码，在服务运行或由外部进程占用目标端口时返回成功状态。
- [ ] `stop` 能正确停止由脚本启动的后端服务，并尽可能清理本项目相关的残留进程而不影响其他 node 进程。
