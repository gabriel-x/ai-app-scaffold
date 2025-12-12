#!/usr/bin/env pwsh
# SDD Enforcement Tool (PowerShell Version)
# Usage: .\scripts\sdd.ps1 {new|check|archive|list|check-active}

$ErrorActionPreference = "Stop"

# Define directories
$DOCS_ROOT = "docs-framework"
$CHANGES_DIR = Join-Path $DOCS_ROOT "changes"
$TEMPLATES_DIR = Join-Path $DOCS_ROOT "templates"
$SPECS_DIR = Join-Path $DOCS_ROOT "specs/functional"

# Define colors (using ANSI escape codes for cross-platform compatibility)
$RED = "[31m"
$GREEN = "[32m"
$YELLOW = "[33m"
$NC = "[0m" # No Color

function Print-Usage {
    Write-Host "Usage: .\scripts\sdd.ps1 {new|check|archive|list|check-active}" -ForegroundColor Cyan
    Write-Host "  new <feature>         Create a new feature proposal" -ForegroundColor Cyan
    Write-Host "  check <feature> plan  Validate spec to proceed to planning" -ForegroundColor Cyan
    Write-Host "  check <feature> implement  Validate spec and plan to proceed to implementation" -ForegroundColor Cyan
    Write-Host "  check-active          (Internal) Check if any active spec exists (for git hook)" -ForegroundColor Cyan
    Write-Host "  archive <feature>     Archive a completed feature" -ForegroundColor Cyan
    Write-Host "  list                  List active features" -ForegroundColor Cyan
}

function Ensure-Templates {
    $specTemplate = Join-Path $TEMPLATES_DIR "spec-template.md"
    if (-not (Test-Path $specTemplate -PathType Leaf)) {
        Write-Host -NoNewline "${RED}Error: Template spec-template.md not found in $TEMPLATES_DIR${NC}"
        Write-Host
        exit 1
    }
}

function Cmd-New {
    param(
        [string]$Feature
    )

    if ([string]::IsNullOrEmpty($Feature)) {
        Write-Host -NoNewline "${RED}Error: Feature name required.${NC}"
        Write-Host
        Print-Usage
        exit 1
    }

    $targetDir = Join-Path $CHANGES_DIR $Feature
    if (Test-Path $targetDir -PathType Container) {
        Write-Host -NoNewline "${RED}Error: Feature '$Feature' already exists.${NC}"
        Write-Host
        exit 1
    }

    Ensure-Templates
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    $specTemplate = Join-Path $TEMPLATES_DIR "spec-template.md"
    $targetSpec = Join-Path $targetDir "spec.md"
    Copy-Item -Path $specTemplate -Destination $targetSpec
    
    # Replace placeholder with feature name
    try {
        (Get-Content $targetSpec) -replace "\[Feature Name\]" , $Feature | Set-Content $targetSpec
    } catch {
        # Ignore errors during replacement, similar to bash version
    }

    Write-Host -NoNewline "${GREEN}✓ Created feature '$Feature' in $targetDir${NC}"
    Write-Host
    Write-Host "Next step: Edit $targetSpec to define your requirements."
    Write-Host
}

function Cmd-Check-Plan {
    param(
        [string]$Feature
    )

    $specFile = Join-Path $CHANGES_DIR "$Feature\spec.md"
    
    if (-not (Test-Path $specFile -PathType Leaf)) {
        Write-Host -NoNewline "${RED}Error: Spec file not found for '$Feature'.${NC}"
        Write-Host
        exit 1
    }

    # Check if spec file contains placeholder text
    $content = Get-Content $specFile -Raw
    if ($content -match "\[Brief description") {
        Write-Host -NoNewline "${RED}Error: Spec file contains default template placeholders.${NC}"
        Write-Host
        Write-Host "Please edit the Summary section in $specFile"
        Write-Host
        exit 1
    }

    Write-Host -NoNewline "${GREEN}✓ Spec for '$Feature' looks valid. You may proceed to create a Plan.${NC}"
    Write-Host
    
    # Create plan.md from template if it doesn't exist
    $planFile = Join-Path $CHANGES_DIR "$Feature\plan.md"
    if (-not (Test-Path $planFile -PathType Leaf)) {
        $planTemplate = Join-Path $TEMPLATES_DIR "plan-template.md"
        Copy-Item -Path $planTemplate -Destination $planFile
        try {
            (Get-Content $planFile) -replace "\[Feature Name\]" , $Feature | Set-Content $planFile
        } catch {
            # Ignore errors during replacement, similar to bash version
        }
        Write-Host -NoNewline "${YELLOW}Created draft plan at $planFile${NC}"
        Write-Host
    }
}

function Cmd-Check-Active {
    # This is used by the git hook.
    # Check if changes directory is not empty
    $changesExists = Get-ChildItem -Path $CHANGES_DIR -Force | Select-Object -First 1
    if (-not $changesExists) {
        Write-Host -NoNewline "${RED}BLOCKER: No active feature spec found in $CHANGES_DIR${NC}"
        Write-Host
        Write-Host "You are trying to commit code without an active SDD feature."
        Write-Host "Run '${YELLOW}.\scripts\sdd.ps1 new <feature-name>${NC}' first."
        Write-Host
        exit 1
    }
    
    # Check if the first found feature's spec is filled out
    $firstFeature = Get-ChildItem -Path $CHANGES_DIR -Directory | Select-Object -First 1 | Select-Object -ExpandProperty Name
    $specFile = Join-Path $CHANGES_DIR "$firstFeature\spec.md"
    $content = Get-Content $specFile -Raw
    
    if ($content -match "\[Brief description") {
         Write-Host -NoNewline "${RED}BLOCKER: The active spec '$firstFeature' is still a template.${NC}"
         Write-Host
         Write-Host "Please fill out $specFile before committing."
         Write-Host
         exit 1
    }

    Write-Host -NoNewline "${GREEN}✓ Active spec found: $firstFeature${NC}"
    Write-Host
    exit 0
}

function Cmd-Archive {
    param(
        [string]$Feature
    )

    if ([string]::IsNullOrEmpty($Feature)) {
        Write-Host -NoNewline "${RED}Error: Feature name required.${NC}"
        Write-Host
        exit 1
    }
    
    $targetDir = Join-Path $CHANGES_DIR $Feature
    if (-not (Test-Path $targetDir -PathType Container)) {
        Write-Host -NoNewline "${RED}Error: Feature '$Feature' not found.${NC}"
        Write-Host
        exit 1
    }

    Write-Host -NoNewline "${YELLOW}Archiving feature '$Feature'...${NC}"
    Write-Host
    
    # Ensure target specs directory exists
    New-Item -ItemType Directory -Path $SPECS_DIR -Force | Out-Null
    
    # Copy spec to permanent specs directory with timestamp
    $dateStr = Get-Date -Format "yyyyMMdd"
    $archiveName = "${Feature}_${dateStr}.md"
    $specFile = Join-Path $targetDir "spec.md"
    $archivePath = Join-Path $SPECS_DIR $archiveName
    Copy-Item -Path $specFile -Destination $archivePath
    
    # Remove the changes directory
    Remove-Item -Path $targetDir -Recurse -Force
    
    Write-Host -NoNewline "${GREEN}✓ Feature '$Feature' archived to $archivePath${NC}"
    Write-Host
    Write-Host -NoNewline "${GREEN}✓ Active change directory removed.${NC}"
    Write-Host
}

function Cmd-List {
    Get-ChildItem -Path $CHANGES_DIR -Directory | Select-Object -ExpandProperty Name | Sort-Object
}

# Main script logic
if ($args.Count -eq 0) {
    Print-Usage
    exit 1
}

$command = $args[0]

switch ($command) {
    "new" {
        if ($args.Count -lt 2) {
            Write-Host -NoNewline "${RED}Error: Feature name required.${NC}"
            Write-Host
            Print-Usage
            exit 1
        }
        Cmd-New -Feature $args[1]
    }
    "check" {
        if ($args.Count -lt 3) {
            Write-Host -NoNewline "${RED}Error: Insufficient arguments for check command.${NC}"
            Write-Host
            Print-Usage
            exit 1
        }
        $feature = $args[1]
        $subCommand = $args[2]
        if ($subCommand -eq "plan" -or $subCommand -eq "implement") {
            Cmd-Check-Plan -Feature $feature
            # Additional check for implement subcommand
            if ($subCommand -eq "implement") {
                $planFile = Join-Path $CHANGES_DIR "$feature\plan.md"
                if (-not (Test-Path $planFile -PathType Leaf)) {
                    Write-Host -NoNewline "${RED}Error: Plan file not found for '$feature'.${NC}"
                    Write-Host
                    exit 1
                }
                $planContent = Get-Content $planFile -Raw
                if ($planContent -match "\[Link to spec.md\]") {
                    Write-Host -NoNewline "${RED}Error: Plan file contains default template placeholders.${NC}"
                    Write-Host
                    Write-Host "Please edit the Analysis section in $planFile"
                    Write-Host
                    exit 1
                }
                Write-Host -NoNewline "${GREEN}✓ Plan for '$feature' looks valid. You may proceed to implement.${NC}"
                Write-Host
            }
        } else {
            Write-Host "Unknown check type. Use 'plan' or 'implement'."
            exit 1
        }
    }
    "check-active" {
        Cmd-Check-Active
    }
    "archive" {
        if ($args.Count -lt 2) {
            Write-Host -NoNewline "${RED}Error: Feature name required.${NC}"
            Write-Host
            Print-Usage
            exit 1
        }
        Cmd-Archive -Feature $args[1]
    }
    "list" {
        Cmd-List
    }
    default {
        Print-Usage
        exit 1
    }
}