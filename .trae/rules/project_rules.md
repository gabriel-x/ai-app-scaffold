# TRAE 项目专有规则

## 1. 通用规则
- **服务管理**：项目内所有服务均需通过服务管理脚本进行管理，包括启动、停止、重启、监控等操作。
前端服务管理脚本位于 `frontend/scripts/client-manager.sh`。
后端服务管理脚本位于 `backend/scripts/server-manager.sh`。
- **日志管理**：项目内所有服务的日志均需统一管理，包括日志文件路径、日志级别、日志格式等。
前端日志文件路径：`frontend/logs/`
后端日志文件路径：`backend/logs/`
日志级别：`INFO`、`DEBUG`、`ERROR`等
日志格式：`[时间] [服务名] [日志级别] [日志内容]`
