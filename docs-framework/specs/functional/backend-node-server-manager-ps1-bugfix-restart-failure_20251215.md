# Feature Specification: backend-node-server-manager-ps1-bugfix-restart-failure

## 1. Overview
**Summary**: 修复并增强 Windows 场景下的整体服务管理体验，覆盖 Windows 安装包中的前端、Node 后端、Python 后端以及总控脚本：
- 在打包目录中，确保通过 `scripts/service.ps1` 的 `start/stop/status/restart` 以及各端独立脚本的对应命令，均能稳定启动、停止和重启服务；
- 消除“停止后端后端口仍被本项目进程占用”“再次启动 `/health` 不通”“总控脚本卡死在前端启动”等问题；
- 收敛 Windows 安装包中 Node 后端运行模式为 `dist` 生产模式，并在停止和重启时完成残留进程清理。

**Rationale**:
- 现象：
  - 第一次安装后，通过总控脚本启动全部服务通常成功，但在执行 `scripts/service.ps1 stop` 后再次 `start`，Node 后端脚本会报告“进程已检测到”却健康检查失败，`/health` 实际不可达；
  - 停止服务后，`backend-node` 自身认为服务未运行，但 10000 端口仍然有 `node dist/server.js` 等本项目进程持续监听，形成“脱管僵尸进程”；
  - 通过总控脚本 `scripts/service.ps1 start` 启动服务时，会卡死在“Executing start for Frontend...” 且无法正常响应 Ctrl+C；
  - Python 后端在多进程、`uvicorn --reload` 场景下，存在多个子进程占用端口，停止时不完全清理，影响再次启动。
- 根因归纳：
  - 停止流程仅依赖 PID 文件或主 PID，未基于端口+命令行全量识别并清理本项目相关进程；
  - 启动流程健康检查策略过于单一，对端口监听和 `/health` 缺少带重试的等待逻辑；
  - Windows 安装包中 Node 后端运行在 `dev/tsx watch` 或开发模式下，多次重启与文件监控行为导致稳定性不足；
  - 总控脚本为“获取退出码”额外嵌套一层 PowerShell 子进程，前端 dev server 的长生命周期被错误绑定到外层命令，导致 start 卡死；
  - Python 后端停止时未清理由 `uvicorn --reload` 派生的所有相关 Python 进程，仅杀主 PID，部分子进程持续占用端口。
- 目标：
  - 为前端、Node 后端、Python 后端以及总控脚本提供统一、可靠的启动/停止/重启语义，确保：
    - 在源码目录和 Windows 安装包目录下均可稳定多轮启停；
    - 任何停止/重启操作后不再遗留监听 10100/10000/10001 的本项目僵尸进程；
  - 将 Windows 安装包中 Node 后端运行模式切换为编译后的 `dist` 生产模式，避免 watch 模式带来的额外不确定性；
  - 通过健康检查与浏览器端到端验证（含 Playwright MCP），证明 `10100` 前端页面及 `10000/10001` 的 `/health` 在多轮重启后仍然稳定可用。

## 2. User Scenarios (User Stories)

- **Scenario 1：停止所有服务后再次启动全部服务（打包目录）**
  - **Input**:
    - 在 Windows 安装包解压目录执行：`.\scripts\service.ps1 stop`；
    - 然后执行：`.\scripts\service.ps1 start`；
  - **Output**:
    - 前端启动并监听 10100 端口，通过浏览器访问 `http://localhost:10100/` 页面正常；
    - Node 后端在 10000 端口正常启动，`http://localhost:10000/health` 返回 2xx；
    - Python 后端在 10001 端口正常启动，`http://localhost:10001/health` 返回 2xx；
    - `scripts\service.ps1 start` 命令自身在合理时间内返回，退出码为 0。
  - **Constraint**: 之前可能残留本项目进程占用 10000/10001。

- **Scenario 2：停止所有服务多轮后再重复启停（打包目录）**
  - **Input**:
    - 在 Windows 安装包解压目录下，多轮执行：
      - `scripts\service.ps1 start` → `scripts\service.ps1 status` → 浏览器/MCP 检查 10100/10000/10001；
      - `scripts\service.ps1 stop` → `scripts\service.ps1 status`；
  - **Output**:
    - 任意一轮结束时，若状态为“已启动”，三个端口页面及 `/health` 均可访问；
    - 任意一轮 `stop` 后，三个服务均被识别为“不在运行”，相关端口不被本项目进程占用；
    - 多轮循环中不出现总控脚本卡死、不返回或误报状态的情况。

- **Scenario 3：前端已启动情况下单独启动/重启 Node 后端**
  - **Input**:
    - 执行 `frontend\scripts\client-manager.ps1 start` 启动前端；
    - 然后执行 `backend-node\scripts\server-manager.ps1 start` 或 `restart`。
  - **Output**:
    - Node 后端在 10000 端口正常启动，`/health` 返回 2xx/3xx；
    - 停止或重启后，`status` 显示正确状态，未误认前端进程或端口为后端；
    - 再次 `start/restart` 仍可稳定通过健康检查。

- **Scenario 4：单独启停/重启 Python 后端**
  - **Input**:
    - 在源码目录或打包目录执行 `backend-python\scripts\server-manager.ps1 start/status/stop/restart`；
  - **Output**:
    - 启动后，Python 后端正确绑定 10001 端口（或配置指定端口），`/health` 返回 2xx；
    - 停止或重启时，通过端口+命令行识别所有相关 Python 进程并杀掉，停止后不再有该端口上的本项目进程；
    - 多轮重启不会出现端口被残留 Python 进程占用的情况。

- **Scenario 5：单独启停/重启前端**
  - **Input**:
    - 执行 `scripts\service.ps1 start:frontend/status:frontend/stop:frontend/restart:frontend` 或 `frontend\scripts\client-manager.ps1 start/status/stop/restart`；
  - **Output**:
    - 启动后 `http://localhost:10100/` 页面可访问且内容完整；
    - 停止后不再有本项目前端进程监听 10100 端口；
    - 重启过程中不出现卡死、Ctrl+C 无法终止等问题。

## 3. Interface Contract (脚本与打包行为约束)

### Endpoints: Node 后端
- `backend-node/scripts/server-manager.ps1 stop`
  - 行为：
    - 若 PID 文件存在且对应进程存在，则优先杀主 PID，并等待端口释放；
    - 若 PID 文件不存在或进程已不存在，则基于端口+命令行匹配识别本项目相关 node 进程（含 `dist/server.js` 等形式），全部杀掉并等待退出；
    - 最终端口应释放，不再有本项目 Node 进程监听目标端口。
- `backend-node/scripts/server-manager.ps1 start`
  - 行为：
    - 在开发源码目录下可使用 `npm run dev` 启动；
    - 在打包安装目录下优先使用 `npm run start` 运行 `dist/server.js`（生产模式）；
    - 启动后进行端口监听与 `/health` 多次重试检查（最多约 20s，允许 2xx/3xx 为健康），通过后返回 0，否则返回非零退出码并输出关键错误信息。
- `backend-node/scripts/server-manager.ps1 restart`
  - 行为：语义等同于顺序执行 `stop` 再 `start`，并沿用上述停止清理和健康检查策略。

### Endpoints: Python 后端
- `backend-python/scripts/server-manager.ps1 stop`
  - 行为：
    - 基于端口+命令行枚举所有与本项目 uvicorn/`--reload` 相关的 Python 进程（含主进程与子进程），逐一杀掉；
    - 停止完成后，该端口上不再有本项目 Python 进程。
- `backend-python/scripts/server-manager.ps1 start`
  - 行为：
    - 使用约定端口（打包默认 10001）启动 uvicorn 服务；
    - 启动后通过端口检查和 HTTP 检查（`/health`）确认健康，成功返回 0。
- `backend-python/scripts/server-manager.ps1 restart`
  - 行为：语义等同于 `stop` 再 `start`，并复用上述清理与健康检查策略。

### Endpoints: 前端
- `frontend/scripts/client-manager.ps1 start`
  - 行为：
    - 启动 Vite dev server，绑定约定端口（打包默认 10100）；
    - 启动后通过 HTTP 检查前端入口是否可访问，成功返回 0。
- `frontend/scripts/client-manager.ps1 stop`
  - 行为：通过端口+命令行识别当前 Vite 前端进程并杀掉，确保不再监听 10100。
- `frontend/scripts/client-manager.ps1 restart`
  - 行为：语义等同于 `stop` 再 `start`。

### Endpoints: 总控脚本（Windows）
- `scripts/service.ps1 start/stop/status/restart`
  - 行为：
    - 不再通过嵌套 PowerShell 子进程执行子脚本，而是在当前会话中直接调用各服务管理脚本；
    - 各命令对前端、Node 后端、Python 后端的 `start/stop/status/restart` 进行编排，同时聚合输出并正确透传退出码；
    - 在 `start` 和 `restart` 流程中，不得出现因前端 dev server 长生命周期导致的总控脚本卡死。

### 打包脚本
- `scripts/package-release-win.js`
  - 行为：
    - 在打包前对 `backend-node` 执行构建（`npm run build`）；
    - 将 `backend-node/dist` 一并打入 Windows 安装包，供生产模式启动使用；
    - 打包结果在解压目录中，配合上述服务管理脚本，可多轮启停和重启而行为一致。

## 4. Acceptance Criteria
- [x] 停止 Node 后端后，相关端口完全释放；无残留本项目相关 node 进程。
- [x] 在前端已启动的情况下，Node 后端可稳定启动与重启，`/health` 返回 2xx/3xx。
- [x] 启动脚本在健康检查失败时返回非零退出码并打印错误上下文；成功时返回 0。
- [x] 在 Windows 安装包解压目录执行多轮 `scripts/service.ps1 start/stop/status/restart` 后，三个服务的运行状态与端口健康检查结果保持一致，不出现“僵尸进程”或假阳性状态。
- [x] 前端、Node 后端、Python 后端的独立脚本（`client-manager.ps1`、`server-manager.ps1` 系列）在源码目录与打包目录均支持 `start/stop/status/restart`，且行为与总控脚本编排结果一致。
