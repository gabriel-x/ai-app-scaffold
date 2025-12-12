# Feature Specification: sdd-powershell-conversion

## 1. Overview
**Summary**: Create a PowerShell version of the existing bash-based SDD (Software Design Document) enforcement tool to enable cross-platform compatibility, specifically for Windows environments.
**Rationale**: The current bash script is only executable in bash environments, limiting its use on Windows systems. A PowerShell version will ensure the SDD tool can be used across all supported platforms.

## 2. User Scenarios (User Stories)
> Describe how the user interacts with the feature.

- **Scenario 1**: Create a new feature proposal
  - **Input**: `./scripts/sdd.ps1 new <feature-name>`
  - **Output**: Creates a new feature directory with spec.md template
  - **Constraint**: Must follow the same directory structure as the bash version

- **Scenario 2**: Validate a spec for planning
  - **Input**: `./scripts/sdd.ps1 check <feature> plan`
  - **Output**: Validates the spec file and creates plan.md if needed
  - **Constraint**: Must perform the same validation checks as the bash version

- **Scenario 3**: Archive a completed feature
  - **Input**: `./scripts/sdd.ps1 archive <feature>`
  - **Output**: Moves the spec to the archived directory with timestamp
  - **Constraint**: Must maintain the same archiving structure as the bash version

- **Scenario 4**: List active features
  - **Input**: `./scripts/sdd.ps1 list`
  - **Output**: Lists all active features in the changes directory
  - **Constraint**: Must display the same information as the bash version

## 3. Interface Contract (Technical Spec)
> Define the script interface and functionality.

### Script Location
- Path: `./scripts/sdd.ps1`

### Command-Line Interface
The PowerShell script must support the exact same command-line interface as the bash script:

| Command | Subcommand | Description |
|---------|------------|-------------|
| `new` | `<feature>` | Create a new feature proposal |
| `check` | `<feature> plan` | Validate spec to proceed to planning |
| `check` | `<feature> implement` | Validate spec and plan to proceed to implementation |
| `check-active` | N/A | Check if any active spec exists (for git hook) |
| `archive` | `<feature>` | Archive a completed feature |
| `list` | N/A | List active features |

### Directory Structure
The script must use the same directory structure as the bash version:
- `docs-framework/changes/`: Active feature specs
- `docs-framework/templates/`: Template files
- `docs-framework/specs/functional/`: Archived specs

## 4. Acceptance Criteria
- [ ] PowerShell script exists at `./scripts/sdd.ps1`
- [ ] Script accepts all the same commands as the bash version
- [ ] Script produces identical output (except for minor formatting differences)
- [ ] Script creates the same directory structure and files
- [ ] Script handles errors gracefully with clear messages
- [ ] Script passes all existing functionality tests
- [ ] Script can be executed on Windows PowerShell 5.x and PowerShell 7.x
