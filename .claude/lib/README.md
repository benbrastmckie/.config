# Shared Utility Libraries

This directory contains 42 modular utility libraries organized into 6 functional subdirectories. This organization was established during the November 2025 refactor to improve discoverability and maintainability.

**Recent Cleanup (November 2025)**: 19 unused scripts archived to `.claude/archive/lib/cleanup-2025-11-19/` (see [Archive Manifest](../archive/lib/cleanup-2025-11-19/README.md) for details).

## Directory Structure

```
.claude/lib/
  README.md           # This file
  core/               # Essential infrastructure (8 libraries)
  workflow/           # Workflow orchestration (9 libraries)
  plan/               # Plan management (7 libraries)
  artifact/           # Artifact management (5 libraries)
  convert/            # Document conversion (4 libraries)
  util/               # Miscellaneous utilities (9 libraries)
```

## Subdirectory Overview

### Core Libraries (8 files) - `core/`
Essential infrastructure libraries required by most commands.

| Library | Purpose |
|---------|---------|
| `base-utils.sh` | Common utility functions (error, warn, info, require_*) |
| `detect-project-dir.sh` | Project directory detection |
| `error-handling.sh` | Error classification, retry logic, recovery |
| `library-sourcing.sh` | Library sourcing utilities |
| `library-version-check.sh` | Library version validation |
| `state-persistence.sh` | State file management |
| `unified-location-detection.sh` | Standard path resolution |
| `unified-logger.sh` | Structured logging interface |

**Sourcing Example:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"
```

### Workflow Libraries (9 files) - `workflow/`
Workflow orchestration and state machine libraries.

| Library | Purpose |
|---------|---------|
| `argument-capture.sh` | Argument parsing and capture |
| `checkpoint-utils.sh` | Checkpoint management for workflow resume |
| `metadata-extraction.sh` | Metadata extraction from artifacts |
| `workflow-detection.sh` | Workflow type detection |
| `workflow-init.sh` | Workflow initialization |
| `workflow-initialization.sh` | Extended workflow setup |
| `workflow-llm-classifier.sh` | LLM-based workflow classification |
| `workflow-scope-detection.sh` | Workflow scope detection |
| `workflow-state-machine.sh` | State machine orchestration |

**Sourcing Example:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh"
```

### Plan Libraries (7 files) - `plan/`
Plan parsing, management, and complexity analysis.

| Library | Purpose |
|---------|---------|
| `auto-analysis-utils.sh` | Automatic complexity analysis |
| `checkbox-utils.sh` | Plan checkbox manipulation |
| `complexity-utils.sh` | Complexity scoring and analysis |
| `parse-template.sh` | Template file parsing |
| `plan-core-bundle.sh` | Core plan parsing functions |
| `topic-decomposition.sh` | Topic breakdown utilities |
| `topic-utils.sh` | Topic directory management |

**Sourcing Example:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/complexity-utils.sh"
```

### Artifact Libraries (5 files) - `artifact/`
Artifact creation, registration, and management.

| Library | Purpose |
|---------|---------|
| `artifact-creation.sh` | Artifact file creation |
| `artifact-registry.sh` | Artifact tracking and querying |
| `overview-synthesis.sh` | Report overview generation |
| `substitute-variables.sh` | Variable substitution in templates |
| `template-integration.sh` | Template system integration |

**Sourcing Example:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/artifact-creation.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/artifact-registry.sh"
```

### Convert Libraries (4 files) - `convert/`
Document conversion between formats.

| Library | Purpose |
|---------|---------|
| `convert-core.sh` | Main conversion orchestration |
| `convert-docx.sh` | DOCX conversion functions |
| `convert-markdown.sh` | Markdown validation |
| `convert-pdf.sh` | PDF conversion functions |

**Sourcing Example:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh"
# convert-core.sh automatically sources the other convert libraries
```

### Utility Libraries (9 files) - `util/`
Miscellaneous utility functions.

| Library | Purpose |
|---------|---------|
| `backup-command-file.sh` | Command file backup |
| `dependency-analyzer.sh` | Dependency graph analysis |
| `detect-testing.sh` | Test environment detection |
| `generate-testing-protocols.sh` | Test protocol generation |
| `git-commit-utils.sh` | Git commit utilities |
| `optimize-claude-md.sh` | CLAUDE.md optimization |
| `progress-dashboard.sh` | Progress visualization |
| `rollback-command-file.sh` | Command file rollback |
| `validate-agent-invocation-pattern.sh` | Agent invocation validation |

**Sourcing Example:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/util/git-commit-utils.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/util/progress-dashboard.sh"
```

## Usage Guidelines

### Sourcing Libraries

Libraries should be sourced using absolute paths with `CLAUDE_PROJECT_DIR`:

```bash
# Recommended pattern
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
```

### Library Dependencies

Some libraries have internal dependencies:
- `artifact/` libraries depend on `core/base-utils.sh` and `core/unified-logger.sh`
- `workflow/` libraries depend on `core/` libraries
- `plan/` libraries depend on `core/base-utils.sh`

### When to Use Which Subdirectory

| Task | Subdirectory |
|------|--------------|
| Error handling, logging | `core/` |
| Workflow orchestration | `workflow/` |
| Plan parsing/manipulation | `plan/` |
| Creating artifacts | `artifact/` |
| Document conversion | `convert/` |
| Git, testing, utilities | `util/` |

## vs scripts/ (Standalone Operational Scripts)

| Aspect | lib/ (Sourced Libraries) | scripts/ (Executable Scripts) |
|--------|--------------------------|-------------------------------|
| **Purpose** | Reusable function libraries | Standalone operational tasks |
| **Execution** | `source lib/core/name.sh` | `bash scripts/name.sh` |
| **Interface** | Function calls | CLI with argument parsing |
| **Output** | Return values, exit codes | Formatted reports |

For standalone scripts, see [scripts/README.md](../scripts/README.md).

## Testing

```bash
# Syntax check all libraries
for f in .claude/lib/*/*.sh; do bash -n "$f"; done

# Run test suite
bash .claude/tests/test_semantic_slug_commands.sh
```

## Archived Libraries

19 libraries with zero external references were archived on 2025-11-19. See the [Archive Manifest](../archive/lib/cleanup-2025-11-19/README.md) for details and restoration instructions.

## Navigation

- [Parent Directory](../README.md)
- [Scripts (Standalone)](../scripts/README.md)
- [Commands](../commands/)
- [Tests](../tests/)
- [CLAUDE.md](../../CLAUDE.md)
