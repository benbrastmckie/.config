# Porting Guide: .claude/ to OpenCode

This guide provides a comprehensive reference for porting the `.claude/` AI development workflow system to OpenCode or similar AI coding tools. Use this document to understand the core architecture, identify portable components, and guide adaptation decisions.

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Summary](#architecture-summary)
3. [Core Components](#core-components)
4. [Key Patterns to Port](#key-patterns-to-port)
5. [Standards and Conventions](#standards-and-conventions)
6. [Component Catalog](#component-catalog)
7. [Porting Priorities](#porting-priorities)
8. [Adaptation Considerations](#adaptation-considerations)

---

## System Overview

The `.claude/` system is a sophisticated multi-agent workflow orchestration framework built for Claude Code. It provides:

- **16 slash commands** for research, planning, implementation, testing, debugging
- **19 specialized AI agents** with model-appropriate task delegation
- **43 bash libraries** for state management, error handling, artifact creation
- **100+ documentation files** following Diataxis framework
- **89 test files** across 7 categories
- **1 skill** (document-converter)

**Key Innovations**:
- 92-97% context reduction via metadata-only passing
- 40-60% time savings via wave-based parallel execution
- 100% delegation success via hard barrier pattern
- Progressive plan structures (Level 0 -> Level 1 -> Level 2)
- Centralized error logging with queryable JSONL format

---

## Architecture Summary

### Three-Tier Agent Hierarchy

```
┌─────────────────────────────────────────────────────────────────┐
│                    TIER 1: COMMANDS                             │
│  (Orchestrators - State machine, workflow scope, coordination)  │
│                                                                 │
│  /create-plan  /implement  /test  /debug  research-mode  /repair   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  TIER 2: COORDINATORS                           │
│    (Supervisors - Parallel orchestration, metadata aggregation) │
│                                                                 │
│  research-coordinator    implementer-coordinator                │
│  testing-coordinator     debug-coordinator                      │
│  repair-coordinator                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   TIER 3: SPECIALISTS                           │
│      (Workers - Focused task execution, artifact creation)      │
│                                                                 │
│  research-specialist    implementation-executor                 │
│  test-executor          debug-analyst                           │
│  plan-architect         repair-analyst                          │
└─────────────────────────────────────────────────────────────────┘
```

### State Machine Workflow

```
initialize → research → plan → implement → test → debug → complete
     │                                              │
     └──────────────── document ←──────────────────┘
```

### Directory Structure

```
.claude/
├── commands/        # Slash command definitions (16 files)
├── agents/          # AI agent behavioral files (19 files)
├── lib/             # Bash libraries (43 files in 7 categories)
│   ├── core/        # Essential infrastructure
│   ├── workflow/    # State machine, checkpoints
│   ├── plan/        # Plan parsing, complexity
│   ├── artifact/    # Artifact creation/tracking
│   ├── convert/     # Document conversion
│   ├── todo/        # Project tracking
│   └── util/        # Miscellaneous utilities
├── docs/            # Documentation (100+ files, Diataxis)
│   ├── reference/   # Quick lookup (standards, commands, agents)
│   ├── guides/      # How-to guides (command usage, development)
│   ├── concepts/    # Explanations (patterns, architecture)
│   └── workflows/   # Tutorials (step-by-step)
├── scripts/         # Validation and utility scripts (20+ files)
├── skills/          # Model-invoked capabilities (1 skill)
├── tests/           # Test suites (89 files)
├── specs/           # Topic-based artifacts (gitignored)
├── data/            # Runtime data (errors.jsonl, checkpoints)
└── tmp/             # Temporary files
```

---

## Core Components

### Essential Documentation (Start Here)

| Document | Path | Purpose |
|----------|------|---------|
| **Standards Index** | `CLAUDE.md` (project root) | Central configuration, all standards references |
| **Architecture Decision Framework** | `docs/guides/architecture/choosing-agent-architecture.md` | When to use hierarchical vs flat |
| **Three-Tier Pattern** | `docs/concepts/three-tier-coordination-pattern.md` | Agent hierarchy responsibilities |
| **Coordinator Patterns** | `docs/reference/standards/coordinator-patterns-standard.md` | Five core coordinator patterns |
| **Return Signals** | `docs/reference/standards/coordinator-return-signals.md` | Agent communication contracts |
| **State System** | `docs/concepts/state-system-patterns.md` | State persistence patterns |
| **Error Logging** | `docs/reference/standards/error-logging-standard.md` | Centralized error handling |
| **Code Standards** | `docs/reference/standards/code-standards.md` | Bash, Task invocation, paths |
| **Directory Protocols** | `docs/concepts/directory-protocols.md` | Topic-based organization |

### Essential Libraries (Core Infrastructure)

| Library | Path | Purpose | Key Functions |
|---------|------|---------|---------------|
| **state-persistence.sh** | `lib/core/` | GitHub Actions-style state | `init_workflow_state()`, `load_workflow_state()`, `append_workflow_state()` |
| **error-handling.sh** | `lib/core/` | Centralized error logging | `log_command_error()`, `parse_subagent_error()`, `ensure_error_log_exists()` |
| **workflow-state-machine.sh** | `lib/workflow/` | 8-state orchestration | `sm_init()`, `sm_transition()`, `sm_get_state()` |
| **unified-location-detection.sh** | `lib/core/` | Path resolution | `detect_claude_root()`, `ensure_specs_dir()` |
| **checkpoint-utils.sh** | `lib/workflow/` | Resume capability | `save_checkpoint()`, `load_checkpoint()`, `delete_checkpoint()` |
| **checkbox-utils.sh** | `lib/plan/` | Plan progress tracking | `mark_phase_complete()`, `add_complete_marker()` |

### Primary Commands (Workflow Entry Points)

| Command | Purpose | Key Agents | Context Reduction |
|---------|---------|------------|-------------------|
| `/create-plan` | Research + planning | research-coordinator, plan-architect | 95% |
| `/implement` | Execute plan phases | implementer-coordinator | 96% |
| `/test` | Run tests, debug failures | testing-coordinator | 86% |
| `/debug` | Root cause analysis | debug-coordinator | 95% |
| `research-mode` | Investigation only | research-specialist | 92% |
| `/repair` | Error pattern fixes | repair-coordinator | 94% |

### Core Agents (Model Selection)

| Agent | Model | Purpose | Used By |
|-------|-------|---------|---------|
| **plan-architect** | opus-4.1 | Design implementation plans | /create-plan, /revise |
| **research-specialist** | sonnet-4.5 | Conduct research | /create-plan, research-mode |
| **implementer-coordinator** | haiku-4.5 | Wave-based execution | /implement |
| **testing-coordinator** | sonnet-4.5 | Parallel test orchestration | /test |
| **debug-coordinator** | sonnet-4.5 | Investigation orchestration | /debug |
| **implementation-executor** | sonnet-4.5 | Execute single phase | /implement |

---

## Key Patterns to Port

### 1. Hard Barrier Subagent Delegation

**Purpose**: Ensure mandatory agent delegation with verification.

**Structure** (3 sub-blocks per delegation):
```markdown
## Block Na: Setup
- State transition
- Variable persistence
- Checkpoint

## Block Nb: Agent Invocation [CRITICAL BARRIER]
**EXECUTE NOW**: USE the Task tool to invoke the agent.

Task {
  subagent_type: "general-purpose"
  description: "..."
  prompt: "Read and follow .claude/agents/agent-name.md ..."
}

## Block Nc: Verification (Hard Barrier)
- Validate artifact exists
- Error logging on failure
- Recovery hints
```

**Benefits**: 100% delegation success, 40-60% context reduction, observable execution.

**Reference**: `docs/concepts/patterns/hard-barrier-subagent-delegation.md`

### 2. Metadata-Only Passing

**Purpose**: 92-97% context reduction between agent tiers.

**Instead of passing full content**:
```yaml
# DON'T: Pass full report content (7,500 tokens)
report_content: |
  # Full Research Report
  [... 200 lines of content ...]
```

**Pass metadata summary**:
```yaml
# DO: Pass metadata (330 tokens, 95% reduction)
report_metadata:
  path: /path/to/report.md
  topic: "authentication patterns"
  findings_count: 8
  recommendations_count: 5
  key_finding: "JWT with refresh tokens recommended"
```

**Reference**: `docs/reference/standards/artifact-metadata-standard.md`

### 3. Wave-Based Parallel Execution

**Purpose**: 40-60% time savings via dependency-aware parallelization.

**Example**:
```yaml
Phase 1: Database Setup      [no dependencies]      → Wave 1
Phase 2: Backend API         [depends_on: [1]]      → Wave 2
Phase 3: Frontend UI         [depends_on: [1]]      → Wave 2 (parallel)
Phase 4: Integration         [depends_on: [2, 3]]   → Wave 3

Sequential: 150 min
Parallel:   110 min (Wave 2 runs phases 2+3 together)
Savings:    27%
```

**Implementation**: Kahn's algorithm for topological sorting.

**Reference**: `docs/concepts/patterns/parallel-execution.md`

### 4. Brief Summary Format

**Purpose**: 96% context reduction for coordinator returns.

**Format** (max 150 characters):
```
"Completed Wave X-Y (Phase A,B) with N tasks. Context: P%. Next: ACTION."
```

**Examples**:
- `"Completed Wave 1 (Phase 3,4) with 25 tasks. Context: 65%. Next: Continue Wave 2."`
- `"Partial Wave 1 (Phase 1) with 8/15 tasks. Context: 75%. Next: Continue."`

**Reference**: `docs/reference/standards/brief-summary-format.md`

### 5. State Machine Orchestration

**Purpose**: Reliable workflow state management across blocks.

**8 Core States**:
1. `initialize` - Setup, scope detection
2. `research` - Research via specialists
3. `plan` - Create implementation plan
4. `implement` - Execute phases
5. `test` - Run test suites
6. `debug` - Debug failures
7. `document` - Update docs
8. `complete` - Terminal state

**Pattern**:
```bash
# Initialize
sm_init "$PLAN_FILE" "$COMMAND_NAME" "$WORKFLOW_TYPE"

# Transition
sm_transition "$STATE_IMPLEMENT" "starting implementation"

# Query
CURRENT_STATE=$(sm_get_state)
```

**Reference**: `docs/concepts/state-system-patterns.md`

### 6. Centralized Error Logging

**Purpose**: Queryable error tracking across all workflows.

**Log Format** (`~/.claude/data/errors.jsonl`):
```json
{
  "timestamp": "2025-12-10T15:30:00Z",
  "command": "/implement",
  "workflow_id": "implement_1234567890",
  "error_type": "state_error",
  "message": "State file not found",
  "details": {"expected_path": "/path/to/state.sh"},
  "block": "bash_block_1c"
}
```

**Error Types**:
- `state_error` - State persistence issues
- `validation_error` - Input validation failures
- `agent_error` - Subagent execution failures
- `parse_error` - Output parsing failures
- `file_error` - File system failures
- `timeout_error` - Operation timeouts
- `execution_error` - General execution failures
- `dependency_error` - Missing dependencies

**Workflow**: `/errors` (query) → `/repair` (analyze + plan) → `/implement` (fix)

**Reference**: `docs/reference/standards/error-logging-standard.md`

---

## Standards and Conventions

### Code Standards

**Bash Three-Tier Sourcing** (enforced by linter):
```bash
# Tier 1: Core infrastructure (fail-fast REQUIRED)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Cannot load state-persistence library"; exit 1
}

# Tier 2: Feature libraries (error handling required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load checkpoint-utils"; exit 1
}

# Tier 3: Optional libraries (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/util/progress-dashboard.sh" 2>/dev/null || true
```

**Task Tool Invocation** (imperative required):
```markdown
# CORRECT: Imperative directive
**EXECUTE NOW**: USE the Task tool to invoke the agent.

# WRONG: Pseudo-code without directive
Task { ... }  # PROHIBITED
```

**Bash Block Size**:
- Hard limit: <400 lines (preprocessing bugs above this)
- Recommended: <300 lines (safe zone)

### Agent Definition Format

```yaml
---
allowed-tools: Read, Write, Edit, Bash, Task
description: Brief agent purpose (one line)
model: sonnet-4.5
model-justification: Why this model fits the task
fallback-model: haiku-4.5
skills: document-converter  # Optional: auto-load skills
---

# Agent Name

## Role
Describe the agent's core responsibility.

## Capabilities
- Capability 1
- Capability 2

## Input Format
Document expected inputs.

## Output Format
Document expected outputs.

## Error Handling
How to handle and return errors.
```

### Command Definition Format

```yaml
---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
argument-hint: <required-arg> [optional-arg]
description: Brief command description
command-type: primary
dependent-agents: agent1, agent2
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
---

# /command-name - Brief Description

## Block 1: Setup
[Setup logic with state initialization]

## Block 2: Agent Invocation [CRITICAL BARRIER]
[Mandatory Task tool invocation]

## Block 3: Verification
[Artifact validation]

## Block 4: Completion
[State transition, summary output]
```

### Directory Protocols

**Topic Structure**:
```
specs/{NNN_topic}/
├── reports/     # Research reports (gitignored)
├── plans/       # Implementation plans (gitignored)
├── summaries/   # Workflow summaries (gitignored)
├── debug/       # Debug reports (COMMITTED to git!)
├── scripts/     # Investigation scripts (temp)
└── outputs/     # Test outputs (temp)
```

**Plan Levels**:
- **Level 0**: Single file, all phases inline
- **Level 1**: Complex phases → separate `phase_N.md` files
- **Level 2**: Complex stages → `phase_N/stage_M.md` subdirectories

---

## Component Catalog

### Commands (16)

| Command | Type | Purpose |
|---------|------|---------|
| `/create-plan` | Primary | Research + implementation planning |
| `/implement` | Primary | Execute plan phases (wave-based) |
| `/test` | Primary | Test execution with debug loop |
| `/debug` | Primary | Root cause analysis |
| `research-mode` | Primary | Investigation-only workflow |
| `/revise` | Primary | Update existing plans |
| `/repair` | Primary | Error pattern analysis + fix |
| `/expand` | Utility | Expand phases to detailed files |
| `/collapse` | Utility | Collapse expanded phases |
| `/convert-docs` | Utility | Document format conversion |
| `/errors` | Utility | Query error logs |
| `/setup` | Utility | Initialize CLAUDE.md |
| `/todo` | Utility | Update TODO.md |
| `/lean-build` | Specialized | Lean theorem proving |
| `/lean-implement` | Specialized | Lean + software hybrid |
| `/lean-plan` | Specialized | Lean-specific planning |

### Agents (19)

**Coordinators (5)**:
- `research-coordinator` - Parallel multi-topic research
- `implementer-coordinator` - Wave-based phase execution
- `testing-coordinator` - Parallel test categories
- `debug-coordinator` - Parallel investigation vectors
- `repair-coordinator` - Error dimension analysis

**Specialists (8)**:
- `plan-architect` (opus) - Implementation plan design
- `research-specialist` (sonnet) - Deep investigation
- `implementation-executor` (sonnet) - Single phase execution
- `test-executor` (sonnet) - Test suite execution
- `debug-analyst` (sonnet) - Failure analysis
- `repair-analyst` (sonnet) - Error pattern analysis
- `research-sub-supervisor` (sonnet) - Research coordination
- `debug-specialist` (opus) - Complex debugging

**Utilities (6)**:
- `topic-naming-agent` (haiku) - LLM-based semantic naming
- `complexity-estimator` (haiku) - Plan complexity scoring
- `spec-updater` (haiku) - Checkbox/status updates
- `todo-analyzer` (haiku) - Project status classification
- `claude-md-analyzer` (haiku) - Standards analysis
- `doc-converter` (haiku) - Document conversion

### Libraries (43)

**Core (8)**: state-persistence, error-handling, workflow-state-machine, unified-location-detection, library-version-check, base-utils, detect-project-dir, unified-logger

**Workflow (9)**: workflow-state-machine, checkpoint-utils, argument-capture, metadata-extraction, workflow-init, workflow-initialization, workflow-detection, workflow-llm-classifier, workflow-scope-detection

**Plan (7)**: plan-core-bundle, checkbox-utils, complexity-utils, auto-analysis-utils, parse-template, topic-decomposition, topic-utils

**Artifact (5)**: artifact-creation, artifact-registry, overview-synthesis, substitute-variables, template-integration

**Convert (4)**: convert-core, convert-docx, convert-pdf, convert-markdown

**Util (9)**: backup-command-file, rollback-command-file, dependency-analyzer, detect-testing, generate-testing-protocols, git-commit-utils, optimize-claude-md, progress-dashboard, validate-agent-invocation-pattern

**Todo (1)**: todo-functions

---

## Porting Priorities

### Priority 1: Core Infrastructure (Port First)

1. **State Persistence** (`lib/core/state-persistence.sh`)
   - Cross-block variable persistence
   - Atomic state file operations
   - State discovery patterns

2. **Error Handling** (`lib/core/error-handling.sh`)
   - Centralized JSONL logging
   - Error type taxonomy
   - Subagent error parsing

3. **Workflow State Machine** (`lib/workflow/workflow-state-machine.sh`)
   - 8-state orchestration
   - Transition validation
   - Idempotent operations

### Priority 2: Agent Architecture (Port Second)

1. **Three-Tier Hierarchy** pattern
   - Command → Coordinator → Specialist
   - Responsibility boundaries
   - Communication protocols

2. **Metadata-Only Passing** pattern
   - Context reduction calculations
   - Summary formats
   - Reference passing

3. **Hard Barrier Delegation** pattern
   - Setup → Execute → Verify structure
   - Mandatory invocation enforcement
   - Artifact validation

### Priority 3: Primary Commands (Port Third)

1. `/create-plan` - Most complex, demonstrates all patterns
2. `/implement` - Wave-based execution showcase
3. `/test` - Test orchestration + debug loop
4. `/debug` - Investigation parallelization

### Priority 4: Supporting Components (Port Last)

1. Utility commands (`/errors`, `/repair`, `/todo`)
2. Validation scripts
3. Documentation system
4. Test infrastructure

---

## Adaptation Considerations

### OpenCode Differences to Address

1. **Tool Invocation Syntax**
   - Claude uses `Task { ... }` pseudo-syntax
   - Adapt to OpenCode's agent/tool invocation pattern

2. **Model Selection**
   - Agents specify preferred models (haiku, sonnet, opus)
   - Map to equivalent OpenCode model tiers

3. **Bash Execution**
   - Heavy reliance on bash blocks for state management
   - May need adaptation if OpenCode has different shell support

4. **File System Access**
   - Assumes specific tool access (Read, Write, Glob, Grep)
   - Verify equivalent capabilities in OpenCode

### Portable Components (No Changes Needed)

- Documentation content (markdown)
- Directory structure conventions
- Error log format (JSONL)
- Plan file format (markdown with YAML)
- Test file patterns

### Likely Adaptation Required

- Command definition format (markdown structure)
- Agent definition format (YAML frontmatter)
- Task tool invocation syntax
- Library sourcing patterns (bash-specific)
- State file format

### Key Questions for OpenCode

1. Does OpenCode support multi-agent coordination?
2. Can OpenCode execute bash scripts with state persistence?
3. What is OpenCode's equivalent to the Task tool?
4. Does OpenCode support model selection per agent?
5. Can OpenCode read/write files with explicit paths?

---

## Quick Reference Links

### Architecture
- [Hierarchical Agents Overview](concepts/hierarchical-agents-overview.md)
- [Three-Tier Coordination Pattern](concepts/three-tier-coordination-pattern.md)
- [Choosing Agent Architecture](guides/architecture/choosing-agent-architecture.md)

### Standards
- [Coordinator Patterns](reference/standards/coordinator-patterns-standard.md)
- [Return Signals](reference/standards/coordinator-return-signals.md)
- [Artifact Metadata](reference/standards/artifact-metadata-standard.md)
- [Brief Summary Format](reference/standards/brief-summary-format.md)
- [Code Standards](reference/standards/code-standards.md)
- [Error Logging](reference/standards/error-logging-standard.md)

### Patterns
- [Hard Barrier Delegation](concepts/patterns/hard-barrier-subagent-delegation.md)
- [Metadata Extraction](concepts/patterns/metadata-extraction.md)
- [Parallel Execution](concepts/patterns/parallel-execution.md)
- [State System Patterns](concepts/state-system-patterns.md)

### Implementation Examples
- [Hierarchical Agent Examples](concepts/hierarchical-agents-examples.md) - 8 practical examples with code
- [Command Patterns Quick Reference](reference/command-patterns-quick-reference.md) - Copy-paste templates

---

## Summary

The `.claude/` system is built on these core innovations:

1. **Hierarchical agent coordination** - 3-tier architecture with clear responsibilities
2. **Metadata-only passing** - 92-97% context reduction
3. **Wave-based parallelization** - 40-60% time savings
4. **Hard barrier delegation** - 100% agent invocation success
5. **State machine orchestration** - Reliable cross-block state
6. **Centralized error logging** - Queryable JSONL format
7. **Progressive plan structures** - Level 0 → 1 → 2 expansion
8. **Topic-based organization** - LLM-named artifact directories

When porting to OpenCode, focus on replicating these patterns rather than exact syntax. The architectural principles are tool-agnostic; the implementation details are Claude-specific.

---

*Document generated from implementation of spec 032_hierarchical_agent_architecture (2025-12-10)*
