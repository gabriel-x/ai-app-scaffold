## 目标与原则
- 以./scaffold目录为根目录，在其下分别为前端、Node.js 后端、Python 后端创建独立目录（库），实现零代码依赖的物理与逻辑隔离。
- 用统一的接口合同（OpenAPI/Spec）与可配置网络端点对齐交互，支持即插即用式组装。
- 以认证（注册/登录/账号管理）、服务管理、主题/光暗模式、通用 UI 为首批共性能力。

## 仓库结构（独立库）
- `frontend/`：React+Vite+TS 前端库（不引入后端代码）。
- `backend-node/`：Express+TypeScript 后端库（不引入前端或 Python 代码）。
- `backend-python/`：FastAPI 后端库（不引入前端或 Node 代码）。
- `docs-framework/`：文档与接口合同库（PRD/架构/实现设计模板、OpenAPI 规范与版本管理）。
- 说明：四者独立开发与发布；仅通过 HTTP(S) 与规范文档发生耦合。可选 `integration/` 提供 Docker Compose 组装样例但不成为任何库的依赖。

## 接口合同（跨库一致性）
- 规范：OpenAPI 3.1（`docs-framework/specs/api/auth.yaml`, `accounts.yaml`, `common.yaml`）。
- 版本：语义化版本（例如 `v1` 路由前缀），变更走 ADR 与 Changelog；向后兼容优先。
- 认证与账户端点约定（Node 与 Python 均实现相同合同）：
  - `POST /api/v1/auth/register`（email、password、profile）
  - `POST /api/v1/auth/login`（email、password → accessToken、refreshToken）
  - `POST /api/v1/auth/refresh`（refreshToken → new accessToken）
  - `GET /api/v1/auth/me`（需要 Bearer Token）
  - `POST /api/v1/auth/logout`（可选，服务端失效刷新令牌）
  - `GET /api/v1/accounts/profile`、`PATCH /api/v1/accounts/profile`
  - `GET /health`（健康检查）
- 响应模型：统一包络 `{ ok: boolean, data?: T, error?: { code: string, message: string } }` 与一致的状态码策略（2xx 成功、4xx 客户端错误、5xx 服务端错误）。
- 安全：JWT（HS256），Header `Authorization: Bearer <token>`；跨库统一过期与刷新策略；CORS 白名单按环境配置。

## 网络端点与配置（可组装）
- 前端：`VITE_API_BASE_URL`、`VITE_API_VERSION`；运行时可切换目标后端。
- Node：`PORT`、`JWT_SECRET`、`ALLOWED_ORIGINS`、`DB_URL`；`BASE_PATH=/api/v1`。
- Python：`PORT`、`JWT_SECRET`、`ALLOWED_ORIGINS`、`DB_URL`；`BASE_PATH=/api/v1`。
- 文档：`.env.example` 与配置向导说明，所有库在 README 写明端口、环境项、示例值。

## 前端库（frontend/）
- 技术栈：`React 18`、`Vite`、`TypeScript`、`react-router-dom@7`、`@tanstack/react-query`、`zustand`、`tailwindcss`、`tailwind-merge`、`lucide-react`、`sonner`、`recharts`。
- 模块：
  - 认证与路由保护：`ProtectedRoute`、`useAuth`（令牌存取、本地会话、刷新流）。
  - 页面：`Login`、`Register`、`Profile`、`AccountSettings`。
  - 布局与导航：`AppLayout`、`AuthLayout`、`Navigation`。
  - 主题与视觉：`useTheme`（暗/亮切换、主题色记忆）、统一卡片与气泡样式、基础 UI 组件库。
  - 数据层：`QueryClientProvider`、请求封装、全局错误与 Toast。
- OpenAPI 客户端：从 `docs-framework/specs` 生成类型安全 API 客户端（生成产物位于前端库内部，避免跨库代码依赖）。
- 测试：Jest + Testing Library（组件/Hook）、Playwright（登录与路由保护）。

## Node 后端库（backend-node/）
- 技术栈：`Express` + `TypeScript` + `helmet/cors/morgan/dotenv` + `bcrypt/jsonwebtoken` +（可选）`multer`。
- 结构：`src/app.ts`（中间件）、`src/routes`、`src/controllers`、`src/services`、`src/repositories`、`src/middlewares`、`src/config`。
- 认证实现：严格遵循 `docs-framework/specs` 的合同；JWT、刷新令牌、`authGuard` 中间件。
- 通用能力：统一错误处理、`/health`、请求校验（`zod` 或轻量校验）。
- 测试：Jest + Supertest（认证与账户端点覆盖）。
- 运维：`npm run dev`、`npm run start`，可选 `pm2`；示例 Dockerfile。

## Python 后端库（backend-python/）
- 技术栈：`FastAPI` + `uvicorn` + `pydantic` + `python-jose`/`PyJWT` + `passlib`；可选 `SQLAlchemy`。
- 结构：`app/main.py`、`app/api/*`、`app/services/*`、`app/models/*`、`app/schemas/*`、`app/core/config.py`。
- 认证实现：与 Node 保持同合同与行为（令牌、刷新、错误模型、状态码）。
- 测试：pytest + httpx。
- 运维：`uvicorn app.main:app --port $PORT`；示例 Dockerfile。

## 文档与规范库（docs-framework/）
- PRD、架构设计、技术选型、实现设计模板；ADR（决策记录）与质量门禁（测试策略、覆盖目标）。
- OpenAPI 目录：`specs/api/*.yaml`，含版本与 Changelog；前后端库仅引用其内容生成或对齐实现，不形成依赖。
- README 模板：运行方式、环境变量、端口约定、脚本与常见问题。

## 组装方式（保持独立，可选集成）
- 开发期：前端 `VITE_API_BASE_URL` 指向任一已启动后端（Node 或 Python），合同一致无需改代码。
- 部署期：用 `integration/docker-compose.yml` 提供示例编排（前端、任选后端、数据库），但各库独立构建与发布。
- 兼容策略：当合同升级到 `v2`，前端可同时内置 `v1/v2` 客户端并按配置选择，支持灰度。

## 测试与质量
- 合同驱动：在 `docs-framework` 对合同写入示例/边界用例；各库用合同生成的类型或 Mock 做契约测试。
- E2E：前端 + 后端登录与路由保护、主题切换；健康检查与 CORS 验证。
- Lint/格式化：各库独立配置；CI 分库运行。
- 安全：秘钥不入库；`.env.example` 与必填项校验；速率限制与暴露面最小化（后续增强）。

## 迭代路线
1) 落地 `docs-framework` 的合同与文档模板（优先 `auth/accounts/health`）。
2) 前端库实现认证、路由保护、主题/UI 基线，并生成 OpenAPI 客户端。
3) Node 后端库实现合同与测试；随后 Python 后端库对齐实现。
4) 各库完善服务管理与 Dockerfiles；提供 `integration` 示例编排。
5) 增补 PRD/架构/实现设计模板与 ADR，完善质量门禁与测试基线。
