# Context Index - Lazy-Loading Quick Map

**Version**: 3.0  
**Created**: 2025-12-23  
**Updated**: 2025-12-29 (Task 246 Phase 5 - Post-Consolidation)  
**Purpose**: Quick reference map for on-demand context loading following OpenAgents patterns

---

## Usage Pattern

**Routing Stage** (Orchestrator Stages 1-3):
- Load NO context files during routing
- Make routing decisions with command frontmatter only
- Target: <10% context window usage

**Execution Stage** (Agent Stage 4+):
- Load only files needed for specific workflow
- Use index.md to identify required files
- Load context on-demand via @.claude/context/{category}/{file}

---

## Core Standards (core/standards/)

**Consolidated files** - Load for delegation, return format, validation

- **delegation.md** (510 lines) - Unified delegation standard
  - Return format schema (all agents MUST follow)
  - Delegation patterns and safety mechanisms
  - Session tracking, cycle detection, timeouts
  - Validation framework
  - Replaces: subagent-return-format.md, subagent-delegation-guide.md, delegation-patterns.md

---

## Core System (core/system/)

**Consolidated files** - Load for state management, artifacts, git, routing, validation

- **state-management.md** (535 lines) - Unified state management standard
  - Status markers and transition rules
  - State schemas (main, archive, maintenance, project)
  - Timestamp formats
  - Status synchronization mechanisms
  - Replaces: status-markers.md, state-schema.md

- **routing-logic.md** (250 lines) - Language extraction and agent mapping
  - Language extraction priority (state.json → TODO.md → default)
  - Agent mapping tables (lean → lean-*, default → general)
  - Routing validation rules
  - Direct routing patterns

- **validation-rules.md** (200 lines) - Return format and artifact validation
  - Required field validation
  - Artifact existence checks (prevents phantom research)
  - Error handling patterns
  - Validation summary logging

---

## Core Standards (core/standards/)

Load for: Task validation, artifact creation, documentation standards

- **status-markers.md** (350 lines) - Status marker definitions and transitions
  - Standard status markers (NOT STARTED, RESEARCHING, PLANNED, etc.)
  - TODO.md vs state.json mapping
  - Command → Status mapping
  - Valid transition rules and diagrams
  - Atomic synchronization protocol
- **tasks.md** (227 lines) - Task entry format, required fields, validation rules
- **documentation.md** (178 lines) - Documentation standards, NO EMOJI policy
- **plan.md** (104 lines) - Implementation plan structure and requirements
- **code.md** (155 lines) - Code quality standards
- **tests.md** (127 lines) - Test requirements and standards
- **patterns.md** (213 lines) - Common design patterns
- **summary.md** (60 lines) - Summary artifact standards
- **report.md** (66 lines) - Report artifact standards
- **analysis.md** (103 lines) - Analysis artifact standards
- **frontmatter-standard.md** (92 lines) - YAML frontmatter requirements
- **commands.md** (73 lines) - Command structure standards

---

## Core System (core/system/)

Load for: Artifact management, git commits, context loading

- **artifact-management.md** (274 lines) - Lazy directory creation, artifact naming (required for all workflows)
- **git-commits.md** (34 lines) - Targeted commit patterns
- **context-guide.md** (89 lines) - Context loading patterns
- **self-healing-guide.md** (153 lines) - Self-healing mechanisms

---

## Core Workflows (core/workflows/)

Load for: Review, task breakdown, sessions

- **review.md** (164 lines) - Review workflow and criteria
- **task-breakdown.md** (270 lines) - Task decomposition patterns
- **sessions.md** (157 lines) - Session management
- **delegation.md** (82 lines) - Delegation context template (temporary context files)

---

## Core Templates (core/templates/)

Load for: Creating new agents, commands, orchestrators

- **subagent-template.md** - Template for creating new agents
- **command-template.md** - Template for creating new commands
- **orchestrator-template.md** - Template for orchestrator patterns
- **meta-guide.md** - Meta-documentation guide
- **state-template.json** - State file template
- **subagent-frontmatter-template.yaml** - Frontmatter template

---

## Project Context (project/)

Load only when needed for language-specific workflows:

### Lean4 Context (project/lean4/)

Load for: Lean implementation tasks (Language: lean)

**Standards**:
- **lean4-style-guide.md** - Lean 4 coding conventions
- **proof-conventions-lean.md** - Lean-specific proof conventions
- **proof-readability-criteria.md** - Proof readability standards

**Tools**:
- **leansearch-api.md** - LeanSearch REST API integration
- **loogle-api.md** - Loogle CLI interface
- **lsp-integration.md** - lean-lsp-mcp integration
- **aesop-integration.md** - Aesop tactic integration
- **mcp-tools-guide.md** - MCP tools overview

**Patterns**:
- **tactic-patterns.md** - Common tactic patterns

**Processes**:
- **end-to-end-proof-workflow.md** - Complete proof development workflow
- **maintenance-workflow.md** - Proof maintenance procedures
- **project-structure-best-practices.md** - Repository organization

**Domain**:
- **dependent-types.md** - Dependent type theory concepts
- **key-mathematical-concepts.md** - Core mathematical concepts
- **lean4-syntax.md** - Lean 4 syntax reference
- **mathlib-overview.md** - Mathlib library overview

**Templates**:
- **definition-template.md** - Definition structure template
- **new-file-template.md** - New Lean file template
- **proof-structure-templates.md** - Proof structure templates
- **maintenance-report-template.md** - Maintenance report template

### Logic Context (project/logic/)

Load for: Proof theory tasks

**Standards**:
- **proof-conventions.md** - Canonical proof principles
- **notation-standards.md** - Notation conventions
- **naming-conventions.md** - Naming standards

**Processes**:
- **modal-proof-strategies.md** - Modal logic proof strategies
- **temporal-proof-strategies.md** - Temporal logic proof strategies
- **proof-construction.md** - General proof construction
- **verification-workflow.md** - Verification procedures

**Domain**:
- **kripke-semantics-overview.md** - Kripke semantics concepts
- **metalogic-concepts.md** - Metalogic theory
- **proof-theory-concepts.md** - Proof theory foundations
- **task-semantics.md** - Task-based semantics

### ModelChecker Context (project/modelchecker/)

Load for: ModelChecker-specific assistance (installation, theories, Z3)

- **installation.md** - Installation commands, documentation paths, troubleshooting
- **architecture.md** - System architecture overview
- **theories.md** - Semantic theory library documentation
- **z3-patterns.md** - Z3 solver patterns

### Repo Context (project/repo/)

Load for: General markdown/documentation tasks (Language: markdown)

- **project-overview.md** - Repository structure and organization
- **self-healing-implementation-details.md** - Self-healing system details

### Math Context (project/math/)

Load for: Mathematical domain tasks

**Algebra**:
- **groups-and-monoids.md** - Group theory concepts
- **rings-and-fields.md** - Ring and field theory

**Order Theory**:
- **partial-orders.md** - Partial order concepts

**Lattice Theory**:
- **lattices.md** - Lattice theory concepts

**Topology**:
- **topological-spaces.md** - Topology concepts

### Physics Context (project/physics/)

Load for: Physics domain tasks

**Dynamical Systems**:
- **dynamical-systems.md** - Dynamical systems concepts

---

## System Context (system/)

Load for: Orchestrator and routing patterns

- **orchestrator-guide.md** - Orchestrator implementation patterns
- **routing-guide.md** - Routing decision logic

---

## Meta Context (Integrated into core/)

Load for: /meta command and system-builder workflows

**When to Load**: Only when executing /meta command or meta subagents (domain-analyzer, agent-generator, workflow-designer, command-creator, context-organizer)

**Note**: Meta context files have been integrated into core/ subdirectories for better organization (Task 267, 2026-01-03)

**Interview Patterns** (core/workflows/):
- **interview-patterns.md** (226 lines) - Progressive disclosure, adaptive questioning, validation checkpoints

**Architecture Design** (core/standards/):
- **architecture-principles.md** (272 lines) - Modular design, hierarchical organization, context efficiency
- **domain-patterns.md** (260 lines) - Development, business, hybrid, and ProofChecker-specific domain patterns

**Agent Templates** (core/templates/):
- **agent-templates.md** (336 lines) - Orchestrator, research, validation, processing, and generation templates

**Loading Strategy**:
- Load core/workflows/interview-patterns.md for domain-analyzer (Stage 4)
- Load core/standards/architecture-principles.md for workflow-designer and agent-generator (Stage 4)
- Load core/standards/domain-patterns.md for domain-analyzer (Stage 4)
- Load core/templates/agent-templates.md for agent-generator (Stage 4)
- Never load during routing (Stages 1-3)

---

## Core Specs (specs/)

Load selectively: Use grep extraction for specific tasks, avoid loading full file

- **TODO.md** - Active task list (large file - load via: `grep -A 50 "^### {task_number}\." TODO.md`)
- **state.json** - Project state tracking (load full file, ~8KB)

---

## Context Loading Examples

**Research Workflow (researcher.md)**:
```
Stage 4 loads:
- @.claude/context/core/orchestration/delegation.md
- @.claude/context/core/orchestration/state-management.md
- @.claude/context/core/orchestration/state-management.md
- grep -A 50 "^### {task_number}\." .claude/specs/TODO.md
- @.claude/specs/state.json

Language-specific:
- If lean: @.claude/context/project/lean4/tools/leansearch-api.md
- If markdown: (no additional context)
```

**Planning Workflow (planner.md)**:
```
Stage 4 loads:
- @.claude/context/core/orchestration/delegation.md
- @.claude/context/core/formats/plan-format.md
- @.claude/context/core/orchestration/state-management.md
- @.claude/context/core/orchestration/state-management.md
- grep -A 50 "^### {task_number}\." .claude/specs/TODO.md
- @.claude/specs/state.json
- Research artifacts from task (if exist)
```

**Implementation Workflow (implementer.md, task-executor.md)**:
```
Stage 4 loads:
- @.claude/context/core/orchestration/delegation.md
- @.claude/context/core/orchestration/state-management.md
- @.claude/context/core/orchestration/state-management.md
- @.claude/context/core/system/git-commits.md
- grep -A 50 "^### {task_number}\." .claude/specs/TODO.md
- @.claude/specs/state.json
- Plan file (if exists)

Language-specific:
- If lean: @.claude/context/project/lean4/standards/lean4-style-guide.md
- If lean: @.claude/context/project/lean4/tools/lsp-integration.md
```

---

## Context Budget Targets (Task 246 Goals)

- **Routing**: <10% context window (Stages 1-3, no context loading)
- **Execution**: 90% context window available (Stage 4+, selective loading)
- **Total context system**: 2,000-2,500 lines (Phase 3 consolidation target)

---

## Consolidation Summary (Task 246 Phase 3)

**Completed**:
- ✓ Delegation files merged: 1,003 → 510 lines (50% reduction)
- ✓ State management files merged: 1,574 → 535 lines (66% reduction)
- ✓ command-lifecycle.md removed: 1,138 lines eliminated (100% reduction)
- ✓ Total reduction: 3,715 → 1,045 lines (72% reduction, 2,670 lines saved)

**Deprecated Files** (1-month deprecation period until 2025-01-29):
- subagent-return-format.md → core/standards/delegation.md#return-format
- subagent-delegation-guide.md → core/standards/delegation.md#delegation-patterns
- state-schema.md → core/system/state-management.md#state-schemas
- command-lifecycle.md → (removed, see agent files for execution patterns)

**Note**: status-markers.md has been moved from core/system/ to core/standards/ (2026-01-08) as it defines standards/conventions rather than system implementation.

---

## Migration Notes (Task 240 + Task 246)

**Phase 1 (Complete)**: Index pattern established, /research migrated to frontmatter
**Phase 2 (Complete)**: All commands migrate to frontmatter, orchestrator simplified
**Phase 3 (Complete)**: Context consolidation, 72% size reduction achieved
**Phase 4 (Planned)**: Testing and documentation

---

## Quick Navigation

**For Delegation**: → `core/standards/delegation.md`
**For State Management**: → `core/system/state-management.md`
**For Artifacts**: → `core/system/artifact-management.md`
**For Git Commits**: → `core/system/git-commits.md`
**For Task Format**: → `core/standards/tasks.md`
**For Plan Format**: → `core/standards/plan.md`
**For Installation Help**: → `project/modelchecker/installation.md`
**For Z3 Patterns**: → `project/modelchecker/z3-patterns.md`
**For Lean Style**: → `project/lean4/standards/lean4-style-guide.md`
**For Proof Conventions**: → `project/logic/standards/proof-conventions.md`
