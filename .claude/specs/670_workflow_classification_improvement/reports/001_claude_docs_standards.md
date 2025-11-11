# Claude Docs Standards and Architectural Guidelines Report

## Metadata
- **Research Topic**: .claude/docs/ standards, patterns, and architectural guidelines
- **Research Date**: 2025-11-11
- **Report Type**: Comprehensive Documentation Analysis
- **Complexity Level**: 2
- **Files Analyzed**: 80+ documentation files across guides, concepts, patterns, reference, and architecture
- **Primary Focus**: Workflow classification standards and patterns

## Executive Summary

The .claude/docs/ directory contains a comprehensive architectural framework organized using the Diataxis methodology (Reference, Guides, Concepts, Workflows). The documentation system provides standards for workflow classification through explicit scope detection patterns, state-based orchestration, and hierarchical agent coordination. Key architectural principles include behavioral injection, executable/documentation separation, and fail-fast error handling.

**Key Findings**:
1. **Workflow Scope Detection Pattern**: 4 explicit workflow types (research-only, research-and-plan, full-implementation, debug-only) with conditional phase execution achieving 71% context savings
2. **State-Based Orchestration**: 8 explicit states with validated transitions replacing implicit phase numbers, achieving 48.9% code reduction
3. **Command Architecture Standards**: 15 architectural standards enforcing execution patterns, behavioral injection, and verification checkpoints
4. **7-Phase Unified Framework**: Standardized orchestration workflow (location → research → plan → implement → test → debug → document → summary) with <30% context usage target
5. **Architectural Patterns**: 11 documented patterns achieving 95-99% context reduction and 40-60% time savings

## Documentation Organization

### Directory Structure (Diataxis Framework)

```
.claude/docs/
├── reference/          # Information-oriented quick lookup (11 files)
│   ├── command-reference.md
│   ├── agent-reference.md
│   ├── command_architecture_standards.md (2,325 lines - CRITICAL)
│   ├── phase_dependencies.md
│   └── orchestration-reference.md
├── guides/            # Task-focused how-to guides (19+ files)
│   ├── orchestration-best-practices.md (UNIFIED FRAMEWORK)
│   ├── command-development-guide.md
│   ├── agent-development-guide.md
│   ├── coordinate-command-guide.md
│   └── *-command-guide.md (8 command guides)
├── concepts/          # Understanding-oriented explanations
│   ├── hierarchical_agents.md
│   ├── development-workflow.md
│   ├── directory-protocols.md
│   ├── writing-standards.md
│   └── patterns/      # Architectural patterns catalog (11 patterns)
├── workflows/         # Learning-oriented tutorials (7 files)
│   ├── orchestration-guide.md
│   ├── context-budget-management.md
│   └── adaptive-planning-guide.md
├── architecture/      # System architecture (4 files)
│   ├── state-based-orchestration-overview.md (2,000+ lines)
│   ├── coordinate-state-management.md
│   └── workflow-state-machine.md
└── troubleshooting/   # Problem-solving guides
    ├── agent-delegation-troubleshooting.md
    └── orchestration-troubleshooting.md
```

**Content Ownership Principle**: Single source of truth per topic
- Patterns catalog: Authoritative for architectural patterns
- Command reference: Authoritative for command syntax
- Agent reference: Authoritative for agent capabilities
- Architecture docs: Authoritative for system design

## Workflow Classification Standards

### 1. Workflow Scope Detection Pattern

**Location**: `docs/concepts/patterns/workflow-scope-detection.md` (581 lines)

**Purpose**: Conditional phase execution based on workflow type, enabling orchestration commands to skip inappropriate phases and reduce cognitive load.

#### Four Scope Types

| Scope Type | Phases Executed | Detection Keywords | Context Savings |
|------------|-----------------|-------------------|-----------------|
| **research-only** | 0-1 | "research", "investigate", "explore" (without "plan"/"implement") | 71% (4,900 → 1,400 tokens) |
| **research-and-plan** | 0-2 | "research and plan", "plan", "design" (without "implement") | 55% |
| **full-implementation** | 0-4, 6 | "implement", "create", "build", "add feature" | Baseline (4,500 tokens) |
| **debug-only** | 0, 1, 5 | "debug", "fix", "investigate failure" | 63% |

#### Keyword Detection Logic

```bash
# Pseudo-code for scope detection
if workflow contains ("debug" OR "fix" OR "investigate failure"):
  scope = "debug-only"
elif workflow contains ("implement" OR "create" OR "build" OR "add"):
  scope = "full-implementation"
elif workflow contains ("plan" OR "design") AND NOT ("research only"):
  scope = "research-and-plan"
else:
  scope = "research-only"  # Default: safest assumption
```

#### Phase Execution Matrix

| Phase | research-only | research-and-plan | full-implementation | debug-only |
|-------|---------------|-------------------|---------------------|------------|
| **0: Location Detection** | ✓ | ✓ | ✓ | ✓ |
| **1: Research** | ✓ | ✓ | ✓ | ✓ |
| **2: Planning** | ✗ | ✓ | ✓ | ✗ |
| **3: Implementation** | ✗ | ✗ | ✓ | ✗ |
| **4: Testing** | ✗ | ✗ | ✓ | ✗ |
| **5: Debugging** | ✗ | ✗ | ✓ (if tests fail) | ✓ |
| **6: Documentation** | ✗ | ✗ | ✓ | ✗ |
| **7: Summary** | ✗ | ✗ | ✓ | ✗ |

**Implementation Library**: `.claude/lib/workflow-detection.sh`
- `detect_workflow_scope(workflow_description)` → returns scope type
- `should_run_phase(workflow_description, phase_name)` → returns true/false

**Benefits**:
- Context budget savings: 71% for research-only workflows
- Clear user experience: Only expected artifacts created
- Reduced execution time: 75% faster for research-only vs full workflow
- Clean artifact output matching user intent

### 2. State-Based Orchestration Architecture

**Location**: `docs/architecture/state-based-orchestration-overview.md` (2,000+ lines)

**Status**: Production (Phase 7 Complete, 2025-11-08)

#### Core Components

**1. State Machine Library** (`workflow-state-machine.sh`):
- 8 explicit states: initialize, research, plan, implement, test, debug, document, complete
- Transition table validation (prevents invalid state changes)
- Atomic state transitions with checkpoint coordination
- 50 comprehensive tests (100% pass rate)

**2. State Persistence Library** (`state-persistence.sh`):
- GitHub Actions-style workflow state files
- Selective file-based persistence (7 critical items, 70% of analyzed state)
- Graceful degradation to stateless recalculation
- 67% performance improvement (6ms → 2ms for CLAUDE_PROJECT_DIR detection)

**3. Checkpoint Schema V2.0**:
- State machine as first-class citizen in checkpoint structure
- Supervisor coordination support for hierarchical workflows
- Error state tracking with retry logic (max 2 retries per state)
- Backward compatible with V1.3 (auto-migration on load)

**4. Hierarchical Supervisors** (State-Aware):
- Research supervisor: 95.6% context reduction (10,000 → 440 tokens)
- Implementation supervisor: 53% time savings via parallel execution
- Testing supervisor: Sequential lifecycle coordination
- 19 comprehensive tests (100% pass rate)

#### Performance Achievements

**Code Reduction**: 48.9% (3,420 → 1,748 lines across 3 orchestrators)
- Exceeded 39% target by 9.9%
- /coordinate: 1,084 → 800 lines (26.2%)
- /orchestrate: 557 → 551 lines (1.1%)
- /supervise: 1,779 → 397 lines (77.7%)

**State Operation Performance**: 67% improvement (6ms → 2ms)
**Context Reduction**: 95.6% via hierarchical supervisors
**Time Savings**: 53% via parallel execution
**Reliability**: 100% file creation maintained

#### Architectural Principles

1. **Explicit Over Implicit**: Named states (STATE_RESEARCH) vs phase numbers (1)
2. **Validated Transitions**: State machine enforces valid state changes
3. **Centralized Lifecycle**: Single state machine library owns all state operations
4. **Selective Persistence**: File-based for expensive operations, stateless for cheap calculations
5. **Hierarchical Context Reduction**: Pass metadata summaries, not full content

**When to Use**:
- Workflow has multiple distinct phases (3+ states)
- Conditional transitions exist (test → debug vs test → document)
- Checkpoint resume required (long-running workflows)
- Multiple orchestrators share similar patterns
- Context reduction through hierarchical supervision needed

**When NOT to Use**:
- Workflow is linear with no branches
- Single-purpose command with no state coordination
- Workflow completes in <5 minutes
- State overhead exceeds benefits (<3 phases)

## Command Architecture Standards

**Location**: `docs/reference/command_architecture_standards.md` (2,325 lines - AUTHORITATIVE)

**Status**: ACTIVE - Must be followed for all modifications

### 15 Core Standards

#### Standard 0: Execution Enforcement

**Purpose**: Distinguish between descriptive documentation and mandatory execution directives

**Enforcement Patterns**:
1. **Imperative Language**: "YOU MUST", "EXECUTE NOW", "MANDATORY" for required actions
2. **Direct Execution Blocks**: `**EXECUTE NOW**: bash commands`
3. **Mandatory Verification Checkpoints**: Explicit file existence checks
4. **Non-Negotiable Agent Prompts**: "THIS EXACT TEMPLATE (No modifications)"
5. **Checkpoint Reporting**: Required completion markers

**Language Strength Hierarchy**:
- Critical: "CRITICAL", "ABSOLUTE REQUIREMENT" (safety, data integrity)
- Mandatory: "YOU MUST", "REQUIRED", "EXECUTE NOW" (essential steps)
- Strong: "Always", "Never", "Ensure" (best practices)
- Standard: "Should", "Recommended" (preferences)
- Optional: "May", "Can", "Consider" (alternatives)

#### Standard 0.5: Subagent Prompt Enforcement

**Extension of Standard 0 for Agent Definition Files**

**Enforcement Patterns**:
- Role Declaration Transformation: "YOU MUST" instead of "I am"
- Sequential Step Dependencies: STEP 1 (REQUIRED BEFORE STEP 2)
- File Creation as Primary Obligation: "PRIMARY OBLIGATION" markers
- Elimination of Passive Voice: Active imperatives only
- Template-Based Output Enforcement: "Use THIS EXACT TEMPLATE"

**Quality Metrics**: Target 95+/100 on enforcement checklist (10 categories × 10 points)

#### Standard 1: Executable Instructions Must Be Inline

**REQUIRED in Command Files**:
- Step-by-step execution procedures with numbered steps
- Tool invocation examples with actual parameter values
- Decision logic flowcharts with conditions and branches
- JSON/YAML structure specifications with all required fields
- Bash command examples with actual paths and flags
- Agent prompt templates (complete, not truncated)
- Critical warnings (e.g., "CRITICAL: Send ALL Task invocations in SINGLE message")
- Error recovery procedures with specific actions
- Checkpoint structure definitions with all fields
- Regex patterns for parsing results

**ALLOWED as External References**:
- Extended background context and rationale
- Additional examples beyond the core pattern
- Alternative approaches for advanced users
- Troubleshooting guides for edge cases
- Historical context and design decisions
- Related reading and deeper dives

#### Standard 11: Imperative Agent Invocation Pattern

**Requirement**: All Task invocations MUST use imperative instructions that signal immediate execution

**Required Elements**:
1. **Imperative Instruction**: `**EXECUTE NOW**: USE the Task tool to invoke...`
2. **Agent Behavioral File Reference**: `Read and follow: .claude/agents/[agent-name].md`
3. **No Code Block Wrappers**: Task invocations must NOT be fenced (no ` ```yaml` blocks)
4. **No "Example" Prefixes**: Remove documentation context
5. **Completion Signal Requirement**: `Return: REPORT_CREATED: ${REPORT_PATH}`

**Anti-Pattern** (Documentation-Only YAML Blocks):
- Wrapping Task invocations in markdown code blocks
- 0% agent delegation rate when this pattern is used
- Causes Claude to interpret as syntax examples rather than executable instructions

**Historical Evidence**:
- Spec 438 (2025-10-24): /supervise agent delegation fix (0% → >90%)
- Spec 495 (2025-10-27): /coordinate and /research fixes (0% → >90%)
- Spec 057 (2025-10-27): /supervise robustness improvements

**Performance Metrics**:
- Agent delegation rate: >90% (all invocations execute)
- File creation rate: 100% (agents create artifacts at expected paths)
- Context reduction: 90% per invocation (behavioral injection vs inline duplication)

#### Standard 12: Structural vs Behavioral Content Separation

**Structural Templates (MUST remain inline)**:
1. Task invocation syntax: `Task { subagent_type, description, prompt }`
2. Bash execution blocks: `**EXECUTE NOW**: bash commands`
3. JSON schemas: Data structure definitions
4. Verification checkpoints: `**MANDATORY VERIFICATION**: file checks`
5. Critical warnings: `**CRITICAL**: error conditions`

**Behavioral Content (MUST be referenced, not duplicated)**:
1. Agent STEP sequences: `STEP 1/2/3` procedural instructions
2. File creation workflows: `PRIMARY OBLIGATION` blocks
3. Agent verification steps: Agent-internal quality checks
4. Output format specifications: Templates for agent responses

**Enforcement Metrics**:
- 90% reduction in code per agent invocation when properly applied
- <30% context window usage throughout workflows
- 100% file creation success rate
- Elimination of synchronization burden

#### Standard 13: Project Directory Detection

**Pattern**: Commands MUST use `CLAUDE_PROJECT_DIR` for project-relative paths

**Implementation**:
```bash
# Detect project directory if not already set
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
```

**Context Awareness**:
- SlashCommand context: Use `CLAUDE_PROJECT_DIR` (git/pwd)
- Standalone script: Use `${BASH_SOURCE[0]}`
- Sourced library: Use `${BASH_SOURCE[0]}`

#### Standard 14: Executable/Documentation File Separation

**Requirement**: Commands MUST separate executable logic from comprehensive documentation

**Two-File Architecture**:
1. **Executable Command File** (`.claude/commands/command-name.md`)
   - Target: <250 lines (simple commands), max 1,200 lines (orchestrators)
   - Content: Bash blocks, phase markers, minimal inline comments (WHAT not WHY)
   - Audience: AI executor (Claude during command execution)

2. **Command Guide File** (`.claude/docs/guides/command-name-command-guide.md`)
   - Size: Unlimited (typically 500-5,000 lines)
   - Content: Architecture, examples, troubleshooting, design decisions
   - Audience: Human developers, maintainers, contributors

**Rationale**: Mixed-purpose files cause four critical failures:
1. Recursive invocation bugs (Claude tries to "invoke /command")
2. Permission denied errors (execution of .md files as bash scripts)
3. Infinite loops (multiple recursive invocations)
4. Context bloat (520+ lines of docs before first executable instruction)

**Migration Results** (7 commands completed 2025-11-07):
- Average reduction: 70% in executable file size
- Guide growth: Average 1,300 lines comprehensive documentation (6.5x more)
- Reliability: 100% execution success rate (vs 25% pre-migration)
- Meta-confusion elimination: 0% incident rate (was 75%)

**Validation**: `.claude/tests/validate_executable_doc_separation.sh`
- File size enforcement (<250 or <1,200 lines)
- Guide existence verification
- Cross-reference validation (bidirectional links)

## Unified 7-Phase Orchestration Framework

**Location**: `docs/guides/orchestration-best-practices.md`

**Status**: Production-ready unified framework (Spec 508)

### Framework Overview

```
Phase 0: Location Detection (Path pre-calculation)
  ↓
Phase 1: Research (2-4 parallel agents)
  ↓
Phase 2: Planning (complexity evaluation)
  ↓
Phase 3: Implementation (wave-based parallel)
  ↓
Phase 4: Testing (conditional)
  ↓
Phase 5: Debugging (conditional, parallel)
  ↓
Phase 6: Documentation
  ↓
Phase 7: Summary (artifact lifecycle)
```

**Context Budget** (21% total target):
- Phase 0: 500-1,000 tokens (4%)
- Phase 1: 600-1,200 tokens (6% - 2-4 agents × 200-300 tokens metadata each)
- Phase 2: 800-1,200 tokens (5%)
- Phase 3: 1,500-2,000 tokens (8%)
- Phase 4-7: 200-500 tokens each (2% each, conditional phases may be 0%)

### Phase 0: Path Pre-Calculation (MANDATORY)

**Purpose**: Calculate all artifact paths BEFORE any agent invocation to enable explicit context injection and lazy directory creation.

**Performance Metrics**:
- Token reduction: 85% (75,600 → 11,000 tokens)
- Speed improvement: 25x faster (25.2s → <1s)
- Directory creation: Lazy (only create when agents produce output)
- Context before research: Zero tokens (paths calculated, not created)

**Implementation**: `unified-location-detection.sh` library
- `perform_location_detection()` function
- JSON-based path extraction
- Automatic topic directory creation
- MANDATORY VERIFICATION checkpoint

**Anti-Pattern**: Agent-based location detection (75,600 tokens, 25 seconds)

### Phase 1: Research (2-4 Parallel Agents)

**Purpose**: Gather information through parallel specialized research agents

**Performance Metrics**:
- Context reduction: 95-99% per report (5,000 → 250 tokens)
- Parallelization: 2-4 agents simultaneously
- Metadata size: 200-300 tokens per report
- Total phase budget: 600-1,200 tokens

**Implementation Pattern**:
1. Calculate report paths (bash pre-calculation)
2. Invoke research-specialist agents (parallel Task invocations)
3. Extract metadata only (title + 50-word summary)
4. Verify report creation (MANDATORY VERIFICATION)

### Command Selection Matrix

| Command | Status | Recommendation | Features |
|---------|--------|----------------|----------|
| **/coordinate** | **Production-Ready** | **USE THIS** (default) | Wave-based parallel (40-60% savings), scope auto-detection, 2,500-3,000 lines |
| **/orchestrate** | In Development | Experimental | PR automation, progress dashboard, metrics tracking, 5,438 lines |
| **/supervise** | In Development | Reference only | Minimal implementation, external docs, 1,939 lines |

**Quick Decision**: Use /coordinate for all production workflows. It is stable, tested, and recommended.

## Architectural Patterns Catalog

**Location**: `docs/concepts/patterns/` (11 patterns)

**Status**: AUTHORITATIVE SOURCE - Single source of truth for architectural patterns

### Core Patterns

#### 1. Behavioral Injection Pattern

**Location**: `behavioral-injection.md` (Used by: all coordinating commands)

**Definition**: Commands inject context into agents via file reads instead of SlashCommand tool invocations, enabling hierarchical multi-agent patterns.

**Benefits**:
- 100% file creation rate through explicit path injection
- <30% context usage by avoiding nested command prompts
- Hierarchical multi-agent coordination through clear role separation
- Parallel execution through independent context injection per agent

**Implementation**:
- Phase 0: Role clarification ("YOU ARE THE ORCHESTRATOR")
- Path pre-calculation (before any agent invocation)
- Context injection via structured data in agent prompts
- Agent reads behavioral file (`.claude/agents/*.md`)

**Anti-Pattern Violation 0**: Inline template duplication (90% unnecessary code)
- Duplicating agent behavioral guidelines in command prompts
- Creates maintenance burden (must sync template with behavioral file)
- Violates single source of truth principle

#### 2. Parallel Execution Pattern

**Location**: `parallel-execution.md` (Used by: /orchestrate, /implement)

**Definition**: Wave-based and concurrent agent execution achieves 40-60% time savings through parallel processing of independent tasks.

**Key Concepts**:
- Wave: Group of tasks that can execute in parallel
- Phase Dependencies: Explicit declaration of which phases depend on others
- Topological Sort: Kahn's algorithm for wave scheduling from dependency graph

**Performance Example**:
- Sequential: Phase 1 (2h) + Phase 2 (3h) + Phase 3 (4h) + Phase 4 (5h) + Phase 5 (2h) = 16 hours
- Wave-based: Wave 1 (2h) + Wave 2 (3h) + Wave 3 (max(4h, 5h) = 5h) + Wave 4 (2h) = 12 hours
- Time savings: 25% (4 hours saved)

**Implementation**: `.claude/lib/parallel-execution.sh`
- `parse_phase_dependencies()` - Extract dependency declarations
- `execute_waves()` - Execute wave groups in parallel

#### 3. Metadata Extraction Pattern

**Location**: `metadata-extraction.md`

**Definition**: Extract title + 50-word summary + paths for 95-99% context reduction

**Format**:
```json
{
  "title": "Research Report Title",
  "summary": "50-word summary of key findings and recommendations",
  "file_path": "/absolute/path/to/report.md",
  "recommendations": ["rec1", "rec2", "rec3"]
}
```

**Performance**: 5,000 tokens → 250 tokens (95% reduction)

**Implementation**: `.claude/lib/metadata-extraction.sh`
- `extract_report_metadata()` - Extract from research reports
- `extract_plan_metadata()` - Extract from implementation plans
- `load_metadata_on_demand()` - Generic metadata loader with caching

#### 4. Hierarchical Supervision Pattern

**Location**: `hierarchical-supervision.md`

**Definition**: Multi-level agent coordination with recursive supervision for complex workflows

**Architecture**:
```
4 Workers (10,000 tokens full output)
    ↓
Supervisor extracts metadata (110 tokens/worker)
    ↓
Orchestrator receives aggregated metadata (440 tokens)
    ↓
95.6% context reduction achieved
```

**Benefits**:
- Research supervisor: 95.6% context reduction
- Implementation supervisor: 53% time savings
- Testing supervisor: Sequential lifecycle coordination
- Enables 10+ research topics (vs 4 without recursion)

#### 5. Verification and Fallback Pattern

**Location**: `verification-fallback.md`

**Definition**: MANDATORY VERIFICATION checkpoints with fallback mechanisms for 100% file creation

**Two-Layer Enforcement**:
1. **Command-Level**: MANDATORY VERIFICATION + fallback creation
2. **Agent-Level**: PRIMARY OBLIGATION + completion signals

**Critical Distinction** (Spec 057):
- Bootstrap fallbacks: PROHIBITED (hide configuration errors)
- Verification fallbacks: REQUIRED (detect tool failures immediately)
- Optimization fallbacks: ACCEPTABLE (performance caches only)

**Performance**: 100% file creation reliability (70% → 100% with checkpoints)

#### 6. Executable/Documentation Separation Pattern

**Location**: `executable-documentation-separation.md`

**Definition**: Separate lean executable logic (<250 lines) from comprehensive documentation (unlimited) to eliminate meta-confusion loops

**Two-File Pattern**:
1. Executable: Bash blocks, phase markers, minimal comments
2. Guide: Architecture, examples, troubleshooting, design decisions

**Benefits**:
- Meta-confusion elimination: 0% incident rate (was 75%)
- Context reduction: 70% average reduction freeing context for execution state
- Independent evolution: Logic changes don't touch docs
- Unlimited documentation: Guides have no size limit
- Fail-fast execution: Lean files obviously executable

**Templates**:
- Executable: `_template-executable-command.md` (56 lines)
- Guide: `_template-command-guide.md` (171 lines)

#### 7. Workflow Scope Detection Pattern

**Location**: `workflow-scope-detection.md` (581 lines)

**Definition**: Conditional phase execution based on workflow type (research-only, research-and-plan, full-implementation, debug-only)

**Benefits**:
- Context budget savings: 71% for research-only workflows
- Clear user experience: Only expected artifacts created
- Reduced execution time: 75% faster for research-only
- Clean artifact output matching user intent

**Implementation**: `.claude/lib/workflow-detection.sh`
- `detect_workflow_scope(workflow_description)` → scope type
- `should_run_phase(workflow_description, phase_name)` → true/false

### Pattern Selection Guide

| Scenario | Recommended Patterns |
|----------|---------------------|
| Command invoking single agent | Behavioral Injection, Verification/Fallback |
| Command coordinating 2-4 agents | + Metadata Extraction, Forward Message |
| Command coordinating 5-9 agents | + Hierarchical Supervision (2 levels) |
| Command coordinating 10+ agents | + Hierarchical Supervision (3 levels, recursive) |
| Long-running workflow (>5 phases) | + Checkpoint Recovery, Context Management |
| Independent parallel tasks | + Parallel Execution |
| Multi-scope orchestration | + Workflow Scope Detection |
| All commands/agents | Executable/Documentation Separation (always apply) |

### Performance Metrics Achieved

- **File Creation Rate**: 100% (with Verification/Fallback)
- **Context Reduction**: 95-99% (with Metadata Extraction)
- **Time Savings**: 40-60% (with Parallel Execution)
- **Context Usage**: <30% throughout workflows (with Context Management)
- **Reliability**: Zero file creation failures (with combined patterns)

## Testing and Validation Standards

**Location**: `docs/guides/testing-patterns.md`, `docs/guides/testing-standards.md`

### Test Organization

**Test Location**: `.claude/tests/`
**Test Runner**: `./run_all_tests.sh`
**Test Pattern**: `test_*.sh` (Bash test scripts)
**Coverage Target**: ≥80% for modified code, ≥60% baseline

### Test Categories

1. **Parsing Utilities**: `test_parsing_utilities.sh` - Plan parsing functions
2. **Command Integration**: `test_command_integration.sh` - Command workflows
3. **Progressive Operations**: `test_progressive_*.sh` - Expansion/collapse
4. **State Management**: `test_state_management.sh` - Checkpoint operations
5. **Shared Utilities**: `test_shared_utilities.sh` - Utility library functions
6. **Adaptive Planning**: `test_adaptive_planning.sh` - Adaptive planning integration (16 tests)
7. **Revise Auto-Mode**: `test_revise_automode.sh` - /revise auto-mode integration (18 tests)
8. **Orchestration Commands**: `test_orchestration_commands.sh` - Orchestration workflows

### Validation Scripts

**Executable/Documentation Separation**:
- `validate_executable_doc_separation.sh` - Verifies pattern compliance
  - File size enforcement (<250 or <1,200 lines)
  - Guide existence verification
  - Cross-reference validation (bidirectional)

**Agent Invocation Pattern**:
- `validate-agent-invocation-pattern.sh` - Detect anti-patterns
  - Documentation-only YAML blocks
  - Missing imperative instructions
  - Missing behavioral file references

### Coverage Requirements

- Aim for >80% coverage on new code
- All public APIs must have tests
- Critical paths require integration tests
- Regression tests for all bug fixes

## Development Workflow Standards

**Location**: `docs/concepts/development-workflow.md`

### 5-Phase Standard Workflow

```
1. Research (/research or /report)
   ↓
2. Planning (/plan with research reports)
   ↓
3. Implementation (/implement with plan)
   ↓
4. Testing (per Testing Protocols)
   ↓
5. Documentation (/document with changes)
```

### Artifact Lifecycle

**Topic-Based Structure**: `specs/{NNN_topic}/`

```
027_authentication/
├── reports/          # Research reports (gitignored)
│   ├── 027_research/             # Multiple reports from one task
│   │   ├── 027_auth_security.md
│   │   ├── 027_auth_frameworks.md
│   │   └── 027_auth_patterns.md
│   └── 028_single_report.md      # Single report (no subdirectory)
├── plans/            # Implementation plans (gitignored)
│   ├── 027_auth_implementation/  # Structured plan subdirectory
│   │   ├── 027_auth_implementation.md  # Level 0 (main plan)
│   │   ├── phase_2_backend.md          # Level 1 (expanded phase)
│   │   └── phase_2/                    # Level 2 (stages)
│   │       ├── stage_1_database.md
│   │       └── stage_2_api.md
├── summaries/        # Workflow summaries (gitignored)
├── debug/            # Debug reports (COMMITTED for history!)
├── scripts/          # Investigation scripts (temp, gitignored)
└── outputs/          # Test outputs (temp, gitignored)
```

**Plan Expansion Levels**:
- **Level 0**: Single file, all phases inline
- **Level 1**: High-complexity phases → separate files
- **Level 2**: Complex phases → staged subdirectories

**Checkbox Propagation**: Changes cascade through plan hierarchy (L2 → L1 → L0)

### Spec Updater Agent Integration

**Purpose**: Manages artifacts and maintains cross-references throughout workflow

**Automatic Triggers**:
- Phase completion
- Context window <20% free
- Plan expansion complete
- Workflow complete

**Actions**:
- Create artifacts in topic directories
- Update plan hierarchy checkboxes (L2 → L1 → L0)
- Maintain cross-references between artifacts
- Create implementation summaries
- Verify gitignore compliance (debug/ committed, others ignored)

## Development Philosophy

**Location**: `docs/concepts/writing-standards.md`

### Core Values

- **Clarity**: Clear, coherent systems
- **Quality**: High standards for all work
- **Coherence**: Well-designed interfaces
- **Maintainability**: Long-term sustainability

### Clean-Break and Fail-Fast Approach

**Clean Break**:
- Delete obsolete code immediately after migration
- No deprecation warnings, compatibility shims, or transition periods
- No archives beyond git history
- Configuration describes what it is, not what it was

**Fail Fast**:
- Missing files produce immediate, obvious bash errors
- Tests pass or fail immediately (no monitoring periods)
- Breaking changes break loudly with clear error messages
- No silent fallbacks or graceful degradation

**Fallback Taxonomy** (Spec 057):
- **Bootstrap fallbacks**: PROHIBITED (hide configuration errors)
- **Verification fallbacks**: REQUIRED (detect errors immediately)
- **Optimization fallbacks**: ACCEPTABLE (performance caches only)

**Avoid Cruft**:
- No historical commentary in active files
- No backward compatibility layers
- No migration tracking spreadsheets (use git commits)
- No "what changed" documentation (use git log)

### Timeless Writing Standards

**Principles**:
- Present-focused documentation
- Avoid historical markers ("New", "Previously", "As of version X")
- No temporal references in active documentation
- Use git log for historical context

## Model Selection Guide

**Location**: `docs/guides/model-selection-guide.md`

### Claude Model Tiers

**Available tiers**:
1. **Haiku**: Fast, cost-effective, simple tasks
2. **Sonnet**: Balanced performance, most workflows
3. **Opus**: Maximum capability, complex reasoning

### Selection Criteria

| Task Type | Recommended Model | Rationale |
|-----------|------------------|-----------|
| Simple file operations | Haiku | Fast, sufficient capability |
| Research reports | Sonnet | Balanced quality/cost |
| Implementation planning | Sonnet | Standard complexity |
| Complex debugging | Opus | Deep reasoning required |
| Multi-agent coordination | Sonnet | Orchestration capability |

### Cost Optimization

- Default to Sonnet for general workflows
- Use Haiku for simple, well-defined tasks
- Reserve Opus for truly complex reasoning
- Monitor token usage and adjust accordingly

## Bash Block Execution Model

**Location**: `docs/concepts/bash-block-execution-model.md`

**Discovered Through**: Specs 620/630 (100% test pass rate)

### Subprocess Isolation Constraint

**Core Principle**: Each bash block runs in separate process, creating constraint that requires explicit state management patterns

**Validated Patterns**:
1. **Fixed Semantic Filenames**: Use workflow-specific names, not PID-based
2. **Save-Before-Source Pattern**: Write state files before sourcing in next block
3. **Library Re-Sourcing**: Source libraries in each bash block
4. **Explicit Exports**: Re-export variables in each block if needed

**Anti-Patterns to Avoid**:
1. `$$`-based IDs (different across blocks)
2. Export assumptions (don't persist across blocks)
3. Premature trap handlers (wrong subprocess context)

### State Management Decision

**File-Based State When**:
- Expensive to recalculate (>30ms)
- Non-deterministic (depends on external state)
- Accumulates across subprocess boundaries

**Stateless Recalculation When**:
- Fast to recalculate (<10ms)
- Deterministic (same inputs → same outputs)
- Ephemeral (no accumulation needed)

## Integration Points for Workflow Classification

### 1. Workflow Scope Detection

**Current Implementation**: `workflow-detection.sh` provides functions for scope detection

**Integration Opportunities**:
- Enhance keyword detection with machine learning classification
- Add confidence scores for ambiguous workflows
- Support compound workflows (e.g., "research, plan, and implement")
- Provide user confirmation for detected scope
- Track scope detection accuracy metrics

### 2. State Machine States

**Current Implementation**: 8 explicit states with validated transitions

**Integration Opportunities**:
- Add state transition probability tracking
- Implement state duration metrics
- Support custom state definitions per workflow type
- Enable state-based workflow templates
- Provide state visualization dashboards

### 3. Phase Execution Matrix

**Current Implementation**: Static matrix in workflow-scope-detection.md

**Integration Opportunities**:
- Dynamic phase selection based on project context
- User-configurable phase requirements
- Phase skip confirmation prompts
- Phase execution time estimates
- Phase dependency inference

### 4. Context Budget Management

**Current Implementation**: 21% total target across 7 phases

**Integration Opportunities**:
- Dynamic budget allocation based on workflow complexity
- Real-time context usage monitoring
- Automatic phase pruning when budget exceeded
- Context budget warnings and recommendations
- Budget optimization suggestions

### 5. Parallel Execution Scheduling

**Current Implementation**: Wave-based execution via Kahn's algorithm

**Integration Opportunities**:
- Machine learning-based dependency inference
- Automatic parallelization opportunity detection
- Resource constraint-aware scheduling
- Execution time prediction
- Parallel execution performance tracking

## Recommendations for Workflow Classification Improvement

### Priority 1: Enhanced Scope Detection

**Current Capability**: 4 predefined scopes, keyword-based detection

**Improvements**:
1. **Confidence Scoring**: Add 0-100% confidence to scope detection
2. **Compound Workflows**: Support multiple scope types in single workflow
3. **User Confirmation**: Prompt for confirmation when confidence <80%
4. **Learning System**: Track scope detection accuracy and refine keywords
5. **Context-Aware Detection**: Consider project history and user patterns

**Implementation**:
- Extend `detect_workflow_scope()` to return confidence score
- Add `detect_compound_workflow()` for multi-scope workflows
- Create `confirm_workflow_scope()` for user interaction
- Implement `track_scope_accuracy()` for learning
- Build `infer_scope_from_context()` for context awareness

### Priority 2: State-Based Workflow Templates

**Current Capability**: Manual state transitions, no templates

**Improvements**:
1. **Template Library**: Pre-defined state sequences for common workflows
2. **Dynamic Templates**: Generate templates based on workflow scope
3. **Template Composition**: Combine templates for compound workflows
4. **Custom Templates**: User-defined workflow patterns
5. **Template Validation**: Verify state sequences are valid

**Implementation**:
- Create `.claude/templates/workflows/` directory
- Define template format (YAML or JSON)
- Implement `load_workflow_template()` function
- Add `apply_workflow_template()` for instantiation
- Build `validate_workflow_template()` for verification

### Priority 3: Intelligent Phase Skipping

**Current Capability**: Static phase matrix, manual skip logic

**Improvements**:
1. **Automatic Skip Detection**: Infer skippable phases from workflow state
2. **User Preferences**: Remember user's phase skip patterns
3. **Project Defaults**: Configure default phases per project
4. **Conditional Phases**: Skip phases based on previous phase results
5. **Skip Confirmation**: Prompt user before skipping critical phases

**Implementation**:
- Add `infer_skippable_phases()` based on state analysis
- Create `.claude/data/user-preferences.json` for patterns
- Support `phase_requirements` in CLAUDE.md
- Implement `conditional_phase_execution()` logic
- Build `confirm_phase_skip()` for user interaction

### Priority 4: Context Budget Optimization

**Current Capability**: Static 21% target, manual allocation

**Improvements**:
1. **Dynamic Allocation**: Adjust budget based on workflow complexity
2. **Real-Time Monitoring**: Track context usage during execution
3. **Automatic Pruning**: Remove low-value content when budget exceeded
4. **Budget Warnings**: Alert when approaching budget limit
5. **Optimization Suggestions**: Recommend context-saving techniques

**Implementation**:
- Create `calculate_dynamic_budget()` function
- Build `monitor_context_usage()` for real-time tracking
- Implement `prune_low_value_content()` for automatic cleanup
- Add `warn_budget_threshold()` for alerts
- Create `suggest_context_optimizations()` for recommendations

### Priority 5: Parallel Execution Inference

**Current Capability**: Manual dependency declarations, Kahn's algorithm

**Improvements**:
1. **Dependency Inference**: Automatically detect phase dependencies
2. **Resource Constraints**: Consider CPU, memory, token limits
3. **Execution Time Prediction**: Estimate time savings from parallelization
4. **Performance Tracking**: Monitor parallel execution efficiency
5. **Optimization Recommendations**: Suggest parallelization opportunities

**Implementation**:
- Build `infer_phase_dependencies()` from phase content
- Add `check_resource_constraints()` for scheduling
- Create `predict_execution_time()` for estimates
- Implement `track_parallel_performance()` for metrics
- Build `suggest_parallelization()` for recommendations

## Cross-References

### Related Patterns
- [Parallel Execution Pattern](docs/concepts/patterns/parallel-execution.md)
- [Metadata Extraction Pattern](docs/concepts/patterns/metadata-extraction.md)
- [Context Management Pattern](docs/concepts/patterns/context-management.md)
- [Behavioral Injection Pattern](docs/concepts/patterns/behavioral-injection.md)
- [Checkpoint Recovery Pattern](docs/concepts/patterns/checkpoint-recovery.md)

### Related Guides
- [Orchestration Best Practices Guide](docs/guides/orchestration-best-practices.md)
- [Command Development Guide](docs/guides/command-development-guide.md)
- [Agent Development Guide](docs/guides/agent-development-guide.md)
- [Orchestration Troubleshooting Guide](docs/guides/orchestration-troubleshooting.md)

### Related Workflows
- [Context Budget Management Tutorial](docs/workflows/context-budget-management.md)
- [Orchestration Guide](docs/workflows/orchestration-guide.md)
- [Adaptive Planning Guide](docs/workflows/adaptive-planning-guide.md)

### Related Reference
- [Command Reference](docs/reference/command-reference.md)
- [Agent Reference](docs/reference/agent-reference.md)
- [Command Architecture Standards](docs/reference/command_architecture_standards.md)
- [Phase Dependencies Reference](docs/reference/phase_dependencies.md)
- [Orchestration Reference](docs/reference/orchestration-reference.md)

### Related Architecture
- [State-Based Orchestration Overview](docs/architecture/state-based-orchestration-overview.md)
- [Coordinate State Management](docs/architecture/coordinate-state-management.md)
- [Workflow State Machine](docs/architecture/workflow-state-machine.md)
- [Hierarchical Supervisor Coordination](docs/architecture/hierarchical-supervisor-coordination.md)

## Summary

The .claude/docs/ directory provides a comprehensive architectural framework for workflow classification and orchestration. Key standards include:

1. **Workflow Scope Detection**: 4 explicit workflow types with 71% context savings
2. **State-Based Orchestration**: 8 explicit states with 48.9% code reduction
3. **7-Phase Unified Framework**: Standardized orchestration achieving <30% context usage
4. **15 Architecture Standards**: Enforcing execution patterns and reliability
5. **11 Architectural Patterns**: Achieving 95-99% context reduction and 40-60% time savings

The documentation system uses the Diataxis framework for organization and maintains single sources of truth for all architectural concepts. All standards are production-validated with comprehensive test coverage.

**For Workflow Classification Improvement**: Focus on enhanced scope detection, state-based templates, intelligent phase skipping, dynamic context budgets, and parallel execution inference as identified in the recommendations section.
