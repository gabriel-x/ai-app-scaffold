# Feature Specification: frontend-client-manager-ps1-align

## 1. Overview
**Summary**: 对齐并增强 Windows PowerShell 前端服务管理脚本 `frontend/scripts/client-manager.ps1`，使其行为与 Linux 下的 `client-manager.sh` 尽可能一致，并在开发环境与打包后的安装环境中都能稳定管理前端服务（启动、停止、重启、状态、日志）。

**Rationale**:
- 目前 Windows 下 PowerShell 脚本稳定性明显弱于 Bash 版本，存在语法错误旧版本遗留、端口管理不完善、依赖安装缺失等问题。
- 前端服务管理脚本是开发体验与发布包的重要组成部分，需要统一的行为与可靠性，避免用户在 Windows 上频繁手动排障。

## 2. User Scenarios (User Stories)

- **Scenario 1：Windows 开发者启动前端服务**
  - **Input**: 在项目根目录运行 `.\frontend\scripts\client-manager.ps1 start`
  - **Output**:
    - 若服务未运行：自动选取或复用合适端口，必要时自动安装依赖，成功启动 Vite 开发服务器，并在控制台输出访问地址与 PID。
    - 若服务已运行：检测到已有前端服务，输出提示而不重复启动。
  - **Constraint**:
    - 依赖 `node`、`npm` 或 `pnpm` 已安装在 PATH 中。

- **Scenario 2：Windows 开发者停止前端服务**
  - **Input**: 在项目根目录运行 `.\frontend\scripts\client-manager.ps1 stop`
  - **Output**:
    - 若 PID 文件对应进程存在：优雅停止并清理 PID 文件。
    - 若 PID 文件缺失或已失效但端口仍被本项目占用：根据端口与进程命令行信息尝试清理残留的本项目 node/vite 进程，并给出明确提示。
  - **Constraint**:
    - 不误杀与本项目无关的进程。

- **Scenario 3：Windows 开发者查看前端服务状态**
  - **Input**: 在项目根目录运行 `.\frontend\scripts\client-manager.ps1 status`
  - **Output**:
    - 若通过 PID 文件确认服务运行：输出绿色 OK 状态、PID 与访问地址，并检测端口可访问性。
    - 若 PID 文件失效但端口上仍有服务监听：给出黄色警告，提示服务可能由外部启动或脚本外部修改，并输出访问地址。
    - 若既无 PID 又无端口监听：输出错误提示，说明服务未运行。
  - **Constraint**:
    - 端口默认值与范围与 Bash 版保持一致，可通过 `.env` 配置 `FRONTEND_PORT` 与 `FRONTEND_PORT_RANGE`。

- **Scenario 4：Windows 用户在 release 包中使用脚本**
  - **Input**: 在解压后的 Windows 安装目录运行 `.\frontend\scripts\client-manager.ps1 status|start|stop|logs`
  - **Output**:
    - 脚本能正确解析执行，不再出现 `Unexpected token '}'` 等语法错误。
    - 各子命令行为与开发环境一致。
  - **Constraint**:
    - release 包中包含与仓库一致、未破坏的脚本文件。

## 3. Interface Contract (脚本接口约定)

本变更不涉及 HTTP API 改动，而是改进本地服务管理脚本的「命令接口」与行为约定。

### 命令接口
- `.\frontend\scripts\client-manager.ps1 start`
  - 使用环境变量 `FRONTEND_PORT`、`FRONTEND_PORT_RANGE` 与默认端口 10100–10199 选择端口。
  - 在缺少 `frontend\node_modules` 时，自动执行依赖安装（优先 `pnpm install`，否则 `npm install`）。
  - 后台启动前端服务，将日志输出到 `frontend/logs/frontend.log`，并将服务进程 PID 写入项目根目录 `.frontend.pid`。

- `.\frontend\scripts\client-manager.ps1 stop`
  - 首选根据 `.frontend.pid` 停止进程。
  - 若 PID 文件无效，但目标端口仍由本项目进程占用，则根据端口 + 进程命令行进行清理。

- `.\frontend\scripts\client-manager.ps1 status`
  - 综合 PID 文件与端口监听信息，输出运行状态与访问地址。

- `.\frontend\scripts\client-manager.ps1 logs`
  - 输出 `frontend/logs/frontend.log` 的最后 50 行。

## 4. Acceptance Criteria
- [ ] `client-manager.ps1` 在干净的 Windows 开发环境中能成功执行 `start`、`status`、`stop`、`logs` 命令，无语法错误。
- [ ] 在前端服务已运行时再次执行 `start`，脚本能正确识别并避免重复启动。
- [ ] 在 PID 文件丢失但端口仍有本项目服务监听时，`status` 能给出合理提示，`stop` 能安全清理本项目进程而不影响其他应用。
- [ ] 使用 `.env` 自定义 `FRONTEND_PORT` 与 `FRONTEND_PORT_RANGE` 时，PowerShell 版本行为与 Bash 版本一致（选取端口策略与访问地址输出一致）。
- [ ] 在 release 安装目录中，`client-manager.ps1` 行为与仓库版本一致，不再出现解析错误。
