# Frontend 库

- 技术栈：React+Vite+TS、react-router-dom、React Query、Zustand、Tailwind、sonner、lucide-react、recharts。
- 运行变量：`VITE_API_BASE_URL` 指向后端地址，如 `http://localhost:3000` 或 `http://localhost:8000`。
- 路由：公开区包含登录与注册；受保护区包含个人主页与账号设置。
- 主题：暗/亮切换，localStorage 记忆。

## .env.example
VITE_API_BASE_URL=http://localhost:3000

## 服务管理脚本
`scripts/client-manager.sh|ps1` 支持 `start/stop/restart/status/logs/health` 与动态端口分配（范围可配 `FRONTEND_PORT_RANGE`）。
开发模式可能遇到 inotify 限制（ENOSPC）导致失败。建议用于最小可运行内核与演示使用 `start`（build + preview，无监视），需要热更新再用 `start:dev`。

### Ubuntu 使用前置
- 赋予执行权限：`chmod +x scripts/client-manager.sh`
- 或通过 bash 调用：`bash scripts/client-manager.sh start`
