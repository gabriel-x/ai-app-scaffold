# SDD (Spec-Driven Development) Workflow & Rules

This project enforces a strict Spec-Driven Development workflow. No code is written without a specification.

## 1. The Golden Rule
> **"No Spec, No Code."**
> You cannot commit code changes (`.ts`, `.py`, `.tsx`) unless there is an active Feature Specification in `docs-framework/changes/`.

## 2. The Workflow Phases

### Phase 1: Propose (Start)
- **Command**: `./scripts/sdd new <feature-name>`
- **Action**: Creates `docs-framework/changes/<feature-name>/spec.md` from template.
- **Gate**: You must fill out the `spec.md`. The default template content is not valid.

### Phase 2: Plan
- **Command**: `./scripts/sdd check <feature-name> plan`
- **Action**: Validates that `spec.md` is complete.
- **Output**: You (or AI) generate `docs-framework/changes/<feature-name>/plan.md`.

### Phase 3: Implement
- **Command**: `./scripts/sdd check <feature-name> implement`
- **Action**: Validates that `plan.md` exists and is complete.
- **Output**: You write code.
- **Enforcement**: Git pre-commit hook will verify that you are in this phase.

### Phase 4: Archive (Finish)
- **Command**: `./scripts/sdd archive <feature-name>`
- **Action**:
  1. Validates that tests pass (optional but recommended).
  2. Merges `spec.md` content into the main `docs-framework/specs/` (Truth Source).
  3. Deletes the `docs-framework/changes/<feature-name>` directory.

## 3. Directory Structure
- `docs-framework/specs/`: The permanent Source of Truth.
- `docs-framework/changes/`: Temporary workspace for active features.
- `docs-framework/templates/`: Templates for specs and plans.
