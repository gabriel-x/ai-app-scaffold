# Implementation Plan: Add Request Logging

## 1. Specification Analysis
- **Spec Document**: `docs-framework/changes/demo-workflow/spec.md`
- **Impacted Areas**:
  - Backend (Node): Add `morgan` or custom middleware.
  - Backend (Python): Add middleware to FastAPI.

## 2. Task List (Step-by-Step)

### Phase 1: Node Backend Implementation
- [ ] **Step 1.1**: Install `morgan` (if not present) and types.
- [ ] **Step 1.2**: Configure `morgan` in `src/app.ts`.

### Phase 2: Python Backend Implementation
- [ ] **Step 2.1**: Add middleware in `app/main.py` to log requests.

## 3. Verification Plan
- **Manual Verification**:
  1. Start backend: `scripts/server-manager.sh start:dev`
  2. `curl http://localhost:10000/health`
  3. Check console output for log line.
