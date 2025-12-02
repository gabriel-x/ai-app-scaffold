# 团队专用命名规则 Baseline（C/S · JS/TS+React+TailwindCSS · Python/Node）

适用标准：SemVer 2.0.0 · ISO 8601/RFC 3339 · BCP 47 · DNS-1123 · Conventional Commits · CloudEvents · OpenTelemetry

## 1) 全局约定
- 字符与分隔：仅 ASCII 小写字母与数字；文件/URL/服务用短横线 -；数据库用下划线 _；配置与指标用点 .；禁用空格和特殊字符
- 大小写风格
  - 目录/文件/URL/服务：kebab-case
  - 变量/JSON 字段：lowerCamelCase；类型/类/React 组件：PascalCase；常量/ENV：SCREAMING_SNAKE_CASE；数据库：snake_case
- 时间与版本：日期 yyyymmdd；时间 RFC 3339 UTC；版本 vMAJOR.MINOR[.PATCH][-rc.N][+build]
- 语言：BCP 47（en, en-us, zh-cn），文件名中用全小写
- 环境：dev, test, stg, prod；临时：preview-<id> 或 pr-<id>
- 机密分级：pub | int | conf | rst；状态：wip | draft | review | approved | deprecated | obsolete
- 资源 ID：前缀 + ULID（推荐）或 UUID（例：cus_01H8ZQ5Y3...）

## 2) 仓库与包
- 仓库名：{product}-{area}[-component]（kebab-case）例：pay-billing-api、core-auth-worker
- Monorepo（建议）：apps/*（app 名）与 packages/*（共享库名）均 kebab-case
- Node 包：@org/{pkg}（例：@acme/billing-api）
- Python 包：分发名 kebab-case（acme-billing-api），import 包 snake_case（acme_billing_api）

## 3) Git 规范
- 分支：{type}/{area}/{short-desc}-{ticket}
  - type ∈ feat|fix|chore|docs|refactor|perf|test|build|ci|revert|hotfix
  - 例：feat/checkout/guest-payment-ABC-1234
- 标签：vX.Y.Z[-rc.N]
- 提交（Conventional Commits）：type(scope): summary
  - 例：feat(checkout): add guest payment with Apple Pay
- PR 标题：[type][area] summary (ABC-1234)

## 4) 前端（React + TS + Tailwind）
- 组件与文件
  - 组件文件：ComponentName.tsx；同名目录/索引：ComponentName/index.ts
  - Hook：useXxx.ts；Context：XxxContext.ts；Provider：XxxProvider.tsx
  - 测试/故事：ComponentName.test.tsx、ComponentName.stories.tsx
  - 路由与页面目录：kebab-case（/billing/invoices、pages/billing/invoices）
- 命名细则
  - 组件/类型/枚举：PascalCase；props/state/函数：lowerCamelCase；常量：SCREAMING_SNAKE_CASE
  - 资源文件：kebab-case（empty-state-illustration.svg）
  - i18n key：dot.case（billing.invoice.emptyState.title）
- Tailwind
  - 优先使用原子类；自定义 CSS 变量 kebab-case（--color-primary），仅在 theme 扩展或封装组件时使用

## 5) 后端（Node.js 或 Python）
- 服务名（亦作容器/K8s Service）：DNS-1123，kebab-case，≤63 字符（billing-api、auth-worker）
- Node 项目：package.json name 对齐服务名；入口文件 kebab-case（server.ts、worker.ts）
- Python 项目：模块 snake_case；入口 main.py；CLI 可执行名 kebab-case
- 环境变量：SCREAMING_SNAKE_CASE（BILLING_API_READ_TIMEOUT_MS）
- 配置键（应用内部/YAML）：dot.case（billing.api.readTimeoutMs=5000）
- 迁移脚本：{yyyymmddhhmmss}__{action}_{object}.sql（20250910153045__create_invoice_items.sql）

## 6) API（REST/GraphQL）
- 版本与路径：/v{major}（/v1）；资源复数 + kebab-case；路径参数 lowerCamelCase
  - 例：GET /v1/customers/{customerId}/invoices
- JSON 字段：lowerCamelCase（createdAt, updatedAt）
- ID：prefix_ULID（cus_01H8...）；错误对象：code（机器读）/message（人读）/requestId
- GraphQL：类型 PascalCase；字段 lowerCamelCase；枚举 SCREAMING_SNAKE_CASE；输入类型以 Input 结尾

## 7) 数据库（PostgreSQL 等）
- schema：domain（billing）
- 表：复数 snake_case（invoice_items）
- 列：snake_case（customer_id, created_at, updated_at, deleted_at）
- 主键：id（bigint/uuid/ulid）；外键：{ref}_id
- 索引：idx_{table}__{col1}_{col2}；唯一：uq_{table}__{col1}_{col2}
- 外键：fk_{table}__{ref_table}；检查：ck_{table}__{desc}
- 关联表：按字母序 a_b（customers_roles）

## 8) 事件与消息（Kafka/Rabbit/CloudEvents）
- 主题/事件名：{domain}.{entity}.{past-tense}.v{major}
  - 例：billing.invoice.paid.v1、auth.user.registered.v1
- CloudEvents type：com.{org}.{domain}.{entity}.{event}.v{major}
- 负载字段：id（ULID）/occurredAt（RFC 3339）/schemaVersion/source

## 9) 可观测性（OpenTelemetry）
- service.name：{product}-{area}-{role}（billing-api）
- 指标名（点分层级；单位放 unit 字段）：{domain}.{subsystem}.{metric}
  - http.server.request.duration（unit=ms）、db.client.operations（unit=1）
- 日志 logger：{domain}.{area}；包含 traceId/spanId
- 告警名：ALR-{area}-{condition}-{severity}
  - 例：ALR-billing-invoice-p95-latency-high

## 10) 制品与发布
- Release：{service} v{semver} - {yyyymmdd}（billing-api v1.4.0 - 20250910）
- Docker：{registry}/{org}/{service}:{semver}
  - 例：ghcr.io/acme/billing-api:1.4.0

## 11) 文档与文件
- 文件名模式：{product}-{area}-{doctype}-{subject}-v{semver}-{yyyymmdd}[-{status}][-{lang}][-{info}].{ext}
- doctype（常用）：prd/mrd/srs/hld/lld/adr/rfc/api/testplan/runbook/sop/spec
- 示例
  - prd-checkout-guest-payment-v1.3-20250910-review-en-us-conf.md
  - srs-auth-login-flow-v2.0-20240825-approved-en-us-int.docx
  - adr-0032-adopt-event-sourcing-v1.0-20240920-approved.md

## 12) 配置与特性开关
- ENV：SCREAMING_SNAKE_CASE（APP_ENV=prod）
- Flag 键：{product}.{area}.{featureName}.v{major}.(enabled|rate|bucket)
  - 例：pay.checkout.guestPayment.v1.enabled

## 13) 测试与质量
- 用例 ID：TC-{AREA}-{####}（TC-BIL-0001）；套件 ID：TS-{AREA}-{####}
- 文件名：{subject}.spec.{lang}、{subject}.e2e.spec.{lang}
  - invoice.service.spec.ts、checkout.guest-payment.e2e.spec.ts

## 14) 采纳与自动化（最小集合）
- pre-commit/commit-msg 钩子：commitlint + lint-staged（Node）、pre-commit（Python）
- CI 校验：分支/标签/制品/文档/迁移文件命名正则
- API/Schema 检查：OpenAPI/GraphQL/DB migration 校验；OpenTelemetry 命名守则检查
- 资产入库（网盘/知识库）：按文档文件名正则拒绝不合规文件