# Frontend 库

- 技术栈：React+Vite+TS、react-router-dom、React Query、Zustand、Tailwind、sonner、lucide-react、recharts。
- 运行变量：`VITE_API_BASE_URL` 供本地代理读取，推荐 `http://localhost:10000`（Node 后端）。
- 路由：公开区包含登录与注册；受保护区包含个人主页与账号设置。
- 主题：暗/亮切换，localStorage 记忆。

## .env.development 示例
VITE_API_BASE_URL=http://localhost:10000

## 开发代理与端口
- 前端开发端口固定 `10100`，同源请求 `'/api'` 由代理改写并转发到后端 `'/api/v1'`。
- 示例：浏览器发起 `POST http://localhost:10100/api/auth/register`，代理转发为 `http://localhost:10000/api/v1/auth/register`。

## 服务管理脚本
`scripts/client-manager.sh|ps1` 支持 `start/stop/restart/status/logs/health` 与动态端口分配（范围可配 `FRONTEND_PORT_RANGE`）。
开发模式可能遇到 inotify 限制（ENOSPC）导致失败。建议用于最小可运行内核与演示使用 `start`（build + preview，无监视），需要热更新再用 `start:dev`。

### Ubuntu 使用前置
- 赋予执行权限：`chmod +x scripts/client-manager.sh`
- 或通过 bash 调用：`bash scripts/client-manager.sh start`
