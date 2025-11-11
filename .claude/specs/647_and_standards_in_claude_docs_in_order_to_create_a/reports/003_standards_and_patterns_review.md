# Standards and Patterns Review for Coordinate Improvements

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Review standards from .claude/docs/ applicable to coordinate improvements
- **Report Type**: Standards analysis and compliance review
- **Complexity Level**: 3

## Executive Summary

Comprehensive review of project standards from `.claude/docs/` identifies 5 critical architectural standards, 4 design patterns, and 2 fundamental execution models that both coordinate improvement plans (636 and 637) must follow. Key findings: Command Architecture Standards (14 standards total) provide non-negotiable requirements for execution enforcement, agent invocation, and file separation. State-Based Orchestration Architecture establishes proven patterns for subprocess isolation and state persistence. Critical gaps identified in both plans regarding Standard 11 (Imperative Agent Invocation) and Standard 14 (Executable/Documentation Separation).

## Standards Overview

### 1. Command Architecture Standards
**Location**: `.claude/docs/reference/command_architecture_standards.md` (2,325 lines)

**Scope**: All files in `.claude/commands/` and `.claude/agents/`

**Status**: ACTIVE - Must be followed for all modifications

**Key Principle**: Command and agent files are AI execution scripts, not traditional software code. Refactoring patterns that work for code may break AI execution.

#### Standard 0: Execution Enforcement

**Purpose**: Distinguish between descriptive documentation and mandatory execution directives using specific linguistic patterns and verification checkpoints.

**Requirements**:
- Use imperative language (YOU MUST, EXECUTE NOW, MANDATORY) for critical steps
- Add explicit verification checkpoints (MANDATORY VERIFICATION blocks)
- Include fallback mechanisms for agent-dependent operations
- Mark agent prompts with "THIS EXACT TEMPLATE (No modifications)"
- Require checkpoint reporting at major milestones

**Language Strength Hierarchy**:
| Strength | Pattern | When to Use |
|----------|---------|-------------|
| Critical | "CRITICAL:", "ABSOLUTE REQUIREMENT" | Safety, data integrity |
| Mandatory | "YOU MUST", "REQUIRED", "EXECUTE NOW" | Essential steps |
| Strong | "Always", "Never", "Ensure" | Best practices |
| Standard | "Should", "Recommended" | Preferences |

**Enforcement Patterns**:

1. **Direct Execution Blocks**: Use explicit "EXECUTE NOW" markers
2. **Mandatory Verification Checkpoints**: Explicit verification Claude MUST execute
3. **Non-Negotiable Agent Prompts**: "THIS EXACT TEMPLATE (No modifications)"
4. **Checkpoint Reporting**: Explicit completion reporting required

**Relationship to Fail-Fast Policy**:
- Verification checkpoints DETECT errors (not hide them)
- Agent responsibility: Agents create artifacts, orchestrator verifies
- Bootstrap fallbacks: PROHIBITED (hide configuration errors)
- Verification fallbacks: REQUIRED (detect tool failures)
- Orchestrator placeholder creation: PROHIBITED (hides agent failures)

**Critical**: Fallback mechanisms must DETECT errors immediately, not create placeholder files masking agent non-compliance.

#### Standard 0.5: Subagent Prompt Enforcement

**Extension of Standard 0** for agent definition files (`.claude/agents/*.md`)

**Key Patterns**:

**Pattern A: Role Declaration Transformation**
- ❌ Weak: "I am a specialized agent"
- ✓ Strong: "YOU MUST perform these exact steps in sequence"

**Pattern B: Sequential Step Dependencies**
- Format: "STEP N (REQUIRED BEFORE STEP N+1)"
- Explicit dependencies prevent step skipping

**Pattern C: File Creation as Primary Obligation**
- Elevate file creation to "PRIMARY OBLIGATION" or "ABSOLUTE REQUIREMENT"
- Priority order: Create file FIRST, then populate, then verify, then return confirmation

**Pattern D: Elimination of Passive Voice**
- ❌ "Reports should be created"
- ✓ "YOU MUST create reports"

**Pattern E: Template-Based Output Enforcement**
- "OUTPUT FORMAT - Use THIS EXACT TEMPLATE (No modifications)"
- Mark sections as REQUIRED, MANDATORY, NON-NEGOTIABLE

**Target**: All priority agents achieve 95+/100 on enforcement rubric

#### Standard 1: Executable Instructions Must Be Inline

**Required in Command Files**:
- ✓ Step-by-step execution procedures with numbered steps
- ✓ Tool invocation examples with actual parameter values
- ✓ Decision logic flowcharts with conditions and branches
- ✓ JSON/YAML structure specifications
- ✓ Bash command examples with actual paths
- ✓ Agent prompt templates (complete, not truncated)
- ✓ Critical warnings (e.g., "CRITICAL: Send ALL Task invocations in SINGLE message")
- ✓ Error recovery procedures
- ✓ Checkpoint structure definitions

**Allowed as External References**:
- ✓ Extended background context
- ✓ Additional examples beyond core pattern
- ✓ Alternative approaches for advanced users
- ✓ Troubleshooting guides for edge cases

#### Standard 11: Imperative Agent Invocation Pattern

**Problem**: Documentation-only YAML blocks create 0% agent delegation rate because they appear as code examples rather than executable instructions.

**Required Elements**:

1. **Imperative Instruction**: Explicit execution markers
   - `**EXECUTE NOW**: USE the Task tool to invoke...`
   - `**INVOKE AGENT**: Use the Task tool with...`

2. **Agent Behavioral File Reference**: Direct reference to agent guidelines
   - Pattern: `Read and follow: .claude/agents/[agent-name].md`

3. **No Code Block Wrappers**: Task invocations must NOT be fenced
   - ❌ WRONG: ` ```yaml` ... `Task {` ... `}` ... ` ``` `
   - ✓ CORRECT: `Task {` ... `}` (no fence)

4. **No "Example" Prefixes**: Remove documentation context
   - ❌ "Example agent invocation:" or "The following shows..."
   - ✓ "**EXECUTE NOW**: USE the Task tool..."

5. **Completion Signal Requirement**: Agent must return explicit confirmation
   - Pattern: `Return: REPORT_CREATED: ${REPORT_PATH}`

**Correct Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: OAuth 2.0 authentication
    - Output Path: /path/to/report.md

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: /path/to/report.md
  "
}
```

**Anti-Pattern (Documentation-Only)**:
```markdown
❌ Example agent invocation:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "Read .claude/agents/research-specialist.md..."
}
```

The code block wrapper prevents execution.
```

**Performance Metrics**:
- Agent delegation rate: >90% (all invocations execute)
- File creation rate: 100% (agents create artifacts at expected paths)
- Context reduction: 90% per invocation (behavioral injection vs inline duplication)

**Historical Context**:
- Spec 438 (2025-10-24): /supervise agent delegation fix (0% → >90%)
- Spec 495 (2025-10-27): /coordinate and /research fixes (0% → >90%)
- Spec 057 (2025-10-27): /supervise robustness improvements

#### Standard 12: Structural vs Behavioral Content Separation

**Requirement**: Commands MUST distinguish between structural templates (inline) and behavioral content (referenced).

**Structural Templates MUST Be Inline**:
1. Task invocation syntax (`Task { subagent_type, description, prompt }`)
2. Bash execution blocks (`**EXECUTE NOW**: bash commands`)
3. JSON schemas (data structure definitions)
4. Verification checkpoints (`**MANDATORY VERIFICATION**: file existence checks`)
5. Critical warnings (`**CRITICAL**: error conditions and constraints`)

**Behavioral Content MUST NOT Be Duplicated**:
1. Agent STEP sequences (in `.claude/agents/*.md` files ONLY)
2. File creation workflows (PRIMARY OBLIGATION blocks in agent files)
3. Agent verification steps (agent-internal quality checks)
4. Output format specifications (templates in agent files)

**Rationale**:
- Single source of truth: Agent behavioral guidelines exist in one location only
- Maintenance burden reduction: 50-67% reduction by eliminating duplication
- Context efficiency: 90% code reduction per agent invocation (150 lines → 15 lines)

**Metrics**:
- 90% reduction in code per agent invocation
- <30% context window usage throughout workflows
- 100% file creation success rate
- Elimination of synchronization burden

#### Standard 13: Project Directory Detection

**Pattern**: Commands MUST use `CLAUDE_PROJECT_DIR` for project-relative paths

**Rationale**:
- `${BASH_SOURCE[0]}` is unavailable in SlashCommand execution context
- Git-based detection handles worktrees correctly
- Consistent with library implementation patterns

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

**Error Diagnostics**: When library sourcing fails, provide enhanced diagnostics showing expected location, actual detection results, and current directory.

#### Standard 14: Executable/Documentation File Separation

**Requirement**: Commands MUST separate executable logic from comprehensive documentation into distinct files

**Two-File Architecture**:

1. **Executable Command File** (`.claude/commands/command-name.md`)
   - Target: <250 lines (simple), max 1,200 lines (complex orchestrators)
   - Content: Bash blocks, phase markers, minimal inline comments (WHAT not WHY)
   - Documentation: Single-line reference to guide file only
   - Audience: AI executor (Claude during command execution)

2. **Command Guide File** (`.claude/docs/guides/command-name-command-guide.md`)
   - Size: Unlimited (typically 500-5,000 lines)
   - Content: Architecture, examples, troubleshooting, design decisions
   - Cross-reference: Links back to executable file
   - Audience: Human developers, maintainers, contributors

**Rationale**: Mixed-purpose files cause recursive invocation bugs, permission denied errors, infinite loops, and context bloat (520+ lines of docs before first executable instruction).

**Evidence**: Pre-migration meta-confusion rate: 75% (15/20 test runs). Post-migration: 0% (0/100 test runs).

**Enforcement**:
- Size limits: <250 lines (simple) or <1,200 lines (orchestrators)
- Cross-reference requirement: Bidirectional links mandatory
- Guide existence: Commands >150 lines MUST have corresponding guide

**Validation**: Automated via `.claude/tests/validate_executable_doc_separation.sh`

**Migration Results** (7 commands, 2025-11-07):
- Average reduction: 70% in executable file size
- Guide growth: Average 1,300 lines (6.5x more than was inline)
- Reliability: 100% execution success rate (vs 25% pre-migration)

### 2. State-Based Orchestration Architecture
**Location**: `.claude/docs/architecture/state-based-orchestration-overview.md` (1,749 lines)

**Status**: Production (Phase 7 Complete)

**Key Achievements**:
- Code reduction: 48.9% (3,420 → 1,748 lines across 3 orchestrators)
- State operations: 67% faster (6ms → 2ms for CLAUDE_PROJECT_DIR detection)
- Context reduction: 95.6% via hierarchical supervisors
- Parallel execution: 53% time savings

**Core Components**:

1. **State Machine Library** (`workflow-state-machine.sh`)
   - 8 explicit states (initialize, research, plan, implement, test, debug, document, complete)
   - Transition table validation
   - Atomic state transitions with checkpoint coordination
   - 50 tests passing (100%)

2. **State Persistence Library** (`state-persistence.sh`)
   - GitHub Actions-style workflow state files
   - Selective file-based persistence (7 critical items, 70% of analyzed state)
   - Graceful degradation to stateless recalculation
   - 67% performance improvement

3. **Checkpoint Schema V2.0**
   - State machine as first-class citizen
   - Supervisor coordination support
   - Error state tracking with retry logic (max 2 retries per state)
   - Backward compatible with V1.3

4. **Hierarchical Supervisors**
   - Research supervisor: 95.6% context reduction
   - Implementation supervisor: 53% time savings
   - Testing supervisor: Sequential lifecycle coordination
   - 19 tests passing (100%)

**Architecture Principles**:

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

### 3. Bash Block Execution Model
**Location**: `.claude/docs/concepts/bash-block-execution-model.md` (642 lines)

**Critical Constraint**: Each bash block runs as **separate subprocess**, not subshell.

**Key Characteristics**:
- Process ID (`$$`) changes between blocks
- All environment variables reset (exports lost)
- All bash functions lost (must re-source libraries)
- Trap handlers fire at block exit, not workflow exit
- Only files written to disk persist across blocks

**What Persists vs What Doesn't**:

**Persists ✓**:
- Files written to filesystem
- State files (via state-persistence.sh)
- Workflow ID (fixed location file)
- Directories (created with `mkdir -p`)

**Does NOT Persist ✗**:
- Environment variables (export lost)
- Bash functions (not inherited)
- Process ID (`$$`) - changes per block
- Trap handlers (fire at block exit)
- Current directory (may reset)

**Recommended Patterns**:

1. **Fixed Semantic Filenames**: Use workflow-based names, not `$$`-based
2. **Save-Before-Source Pattern**: Save state ID to fixed location before sourcing
3. **State Persistence Library**: Use `.claude/lib/state-persistence.sh`
4. **Library Re-sourcing**: Re-source all libraries in each block with source guards
5. **Cleanup on Completion Only**: Set cleanup traps only in final completion function

**Critical Libraries for Re-sourcing**:

Core state management:
1. `workflow-state-machine.sh` - State machine operations
2. `state-persistence.sh` - State file operations
3. `workflow-initialization.sh` - Path detection and initialization

Error handling and logging:
4. `error-handling.sh` - Fail-fast error handling
5. `unified-logger.sh` - Progress markers and completion summaries (REQUIRED for emit_progress, display_brief_summary)
6. `verification-helpers.sh` - File creation verification

**Critical Requirements**:
- MUST include `set +H` at start of every bash block (prevents history expansion errors)
- MUST include unified-logger.sh for emit_progress and display_brief_summary functions
- Source guards in libraries make multiple sourcing safe and efficient

**Anti-Patterns**:
1. Using `$$` for cross-block state
2. Assuming exports work across blocks
3. Premature trap handlers
4. Code review without runtime testing

**Historical Context**: Patterns discovered through Spec 620 (bash history expansion fixes) and Spec 630 (state persistence architecture). 100% test pass rate achieved.

### 4. Verification and Fallback Pattern
**Location**: `.claude/docs/concepts/patterns/verification-fallback.md` (448 lines)

**Definition**: Commands and agents validate file creation after every write operation and implement fallback mechanisms when files don't exist.

**Three Components**:
1. **Path Pre-Calculation**: Calculate all file paths before execution
2. **Verification Checkpoints**: MANDATORY VERIFICATION after each file creation
3. **Fallback Mechanisms**: Create missing files if verification fails

**Relationship to Fail-Fast Policy**:

**Detection (Fail-Fast Component)**:
- MANDATORY VERIFICATION exposes file creation failures immediately
- No silent continuation when expected files missing
- Clear diagnostics showing exactly what failed and where
- Workflow terminates with troubleshooting guidance

**Agent Responsibility (Fail-Fast Enforcement)**:
- Agents must create their own artifacts using Write tool
- Orchestrator verifies existence (detection mechanism)
- Orchestrator does NOT create placeholder files (would mask agent failures)
- Missing files indicate agent behavioral issues requiring fixes

**Recovery Through Failure**:
- Verification fails → Clear error with diagnostic steps
- User reviews agent behavioral file and invocation
- User fixes root cause (agent prompt, file path logic, etc.)
- Result: Actual problems solved, not masked

**Critical Distinction** (Spec 057):
- Bootstrap fallbacks: PROHIBITED (hide configuration errors)
- Verification checkpoints: REQUIRED (detect tool failures)
- Placeholder file creation: PROHIBITED (hides agent failures)
- Optimization fallbacks: ACCEPTABLE (performance cache degradation)

**Performance Impact**:
- Before pattern: 7/10 (70%) file creation success rate
- After pattern: 10/10 (100%) file creation success rate
- Improvement: +43% average across commands

**Real Metrics from Plan 077**:
| Command | Before | After | Improvement |
|---------|--------|-------|-------------|
| /report | 70% | 100% | +43% |
| /plan | 60% | 100% | +67% |
| /implement | 80% | 100% | +25% |

### 5. Context Management Pattern
**Location**: `.claude/docs/concepts/patterns/context-management.md` (292 lines)

**Definition**: Comprehensive pattern combining multiple techniques to minimize token usage: metadata extraction, context pruning, forward message passing, layered context architecture, and aggressive cleanup.

**Target**: <30% context usage across entire workflow lifecycle

**Why This Matters**: Without active context management, workflows overflow after 2 phases (70-90% context). With management, all 7 phases use <30% context.

**Five Techniques**:

1. **Metadata Extraction**: Return 200-300 token summaries instead of 5,000-10,000 token full content
2. **Context Pruning**: Remove completed phase data after extracting metadata (96% reduction)
3. **Forward Message Pattern**: Pass metadata directly without re-summarization (0 additional tokens)
4. **Layered Context Architecture**: 4 layers with different retention policies
5. **Checkpoint-Based State**: Store state externally, load on-demand

**Layered Context Architecture**:
- Layer 1 (Permanent): User request, workflow type, current phase - 500-1,000 tokens
- Layer 2 (Phase-Scoped): Current phase instructions, agent invocations - 2,000-4,000 tokens
- Layer 3 (Metadata): Artifact paths, phase summaries, key findings - 200-300 tokens per phase
- Layer 4 (Transient): Full agent responses, detailed logs - 0 tokens (pruned immediately)

**Context Reduction Metrics**:
| Workflow | Without Management | With Management | Reduction |
|----------|-------------------|-----------------|-----------|
| 4-agent research | 20,000 tokens (80%) | 1,000 tokens (4%) | 95% |
| 7-phase /orchestrate | 40,000 tokens (160% overflow) | 7,000 tokens (28%) | 82% |
| Hierarchical (3 levels) | 60,000 tokens (240% overflow) | 4,000 tokens (16%) | 93% |

**Scalability Improvements**:
- Phases supported: 2-3 → 7-10
- Agents coordinated: 2-4 → 10-30
- Workflow completion rate: 40% → 100% (no context overflows)

## Recommendations for Both Plans

### Critical Requirements

Both coordinate improvement plans (636 and 637) MUST comply with:

1. **Standard 0 (Execution Enforcement)**:
   - Use imperative language (YOU MUST, EXECUTE NOW, MANDATORY)
   - Add MANDATORY VERIFICATION checkpoints after all file operations
   - Include fallback mechanisms that DETECT errors (not create placeholder files)
   - Mark agent prompts with "THIS EXACT TEMPLATE (No modifications)"

2. **Standard 11 (Imperative Agent Invocation)**:
   - All Task invocations MUST use "**EXECUTE NOW**: USE the Task tool..."
   - NO code block wrappers (` ```yaml`) around Task invocations
   - Direct reference to agent behavioral files (`.claude/agents/[name].md`)
   - Require completion signals (e.g., `Return: REPORT_CREATED: ${PATH}`)

3. **Standard 12 (Structural vs Behavioral Separation)**:
   - Keep structural templates inline (Task syntax, bash blocks, JSON schemas)
   - Reference behavioral content from agent files (no duplication)
   - Target: 90% code reduction per agent invocation

4. **Standard 13 (Project Directory Detection)**:
   - Use `CLAUDE_PROJECT_DIR` pattern (not `${BASH_SOURCE[0]}`)
   - Include enhanced error diagnostics for library sourcing failures

5. **Standard 14 (Executable/Documentation Separation)**:
   - Target: <1,200 lines for orchestrator executable files
   - Create comprehensive command guide (unlimited size)
   - Maintain bidirectional cross-references

### State-Based Orchestration Integration

Both plans should leverage state-based orchestration architecture:

1. **State Machine Operations**:
   - Use explicit state enumeration (STATE_RESEARCH, STATE_PLAN, etc.)
   - Implement validated transitions via `sm_transition()`
   - Coordinate atomic state transitions with checkpoint saves

2. **Selective State Persistence**:
   - Use file-based state for expensive operations (>30ms)
   - Use stateless recalculation for fast operations (<10ms)
   - Follow GitHub Actions pattern (init → load → append)

3. **Hierarchical Supervisors**:
   - Use supervisors for 4+ parallel workers
   - Aggregate metadata (95% context reduction)
   - Pass summaries to orchestrator, not full content

### Bash Block Execution Model Compliance

Both plans MUST follow subprocess isolation patterns:

1. **Fixed Semantic Filenames**:
   - Use `workflow_coordinate_${WORKFLOW_ID}.sh` (not `$$`-based)
   - Save workflow ID to fixed location file

2. **Library Re-sourcing**:
   - Include `set +H` at start of every bash block
   - Re-source all 6 critical libraries in each block
   - Include unified-logger.sh for emit_progress and display_brief_summary

3. **State Persistence**:
   - Use state-persistence.sh library
   - Load workflow state in each block
   - Append new state using append_workflow_state()

4. **Cleanup on Completion Only**:
   - Set trap handlers ONLY in final completion function
   - No premature cleanup in early blocks

### Verification and Fallback Pattern

Both plans MUST implement comprehensive verification:

1. **Path Pre-Calculation**:
   - Calculate ALL artifact paths before any agent invocations
   - Display paths for user visibility
   - Verify parent directories exist

2. **MANDATORY VERIFICATION Checkpoints**:
   - After EVERY file creation operation
   - Check file exists with `[ -f "$FILE_PATH" ]`
   - Verify file size > 0 bytes
   - Log verification results

3. **Fallback Mechanisms**:
   - Trigger ONLY when verification fails
   - DETECT failure with clear diagnostics (not create placeholder)
   - Terminate workflow with troubleshooting steps
   - User fixes root cause before re-running

**CRITICAL**: Fallbacks DETECT errors, they do NOT create placeholder files masking agent failures. This maintains fail-fast integrity.

### Context Management Strategy

Both plans should implement aggressive context management:

1. **Metadata Extraction**:
   - All agents return metadata only (200-300 tokens)
   - Extract metadata from full outputs using `.claude/lib/metadata-extraction.sh`

2. **Context Pruning**:
   - Prune completed phase data after metadata extraction
   - Use `.claude/lib/context-pruning.sh` utilities
   - Target: 96% reduction per phase

3. **Forward Message Pattern**:
   - Pass metadata directly without re-summarization
   - Format: `FORWARDING RESULTS: {metadata}`

4. **Layered Context Architecture**:
   - Layer 1 (Permanent): 500-1,000 tokens
   - Layer 2 (Phase-Scoped): 2,000-4,000 tokens (pruned after phase)
   - Layer 3 (Metadata): 200-300 tokens per phase
   - Layer 4 (Transient): 0 tokens (pruned immediately)

5. **Target**: <30% context usage across entire workflow

## Standards Compliance Gaps

### Plan 636 Gaps

Based on review of spec 636 context:

1. **Standard 11 Compliance**: Need verification that all agent invocations use imperative pattern with no code block wrappers
2. **Standard 14 Compliance**: Coordinate.md size (1,084 lines) acceptable for complex orchestrator, but verify corresponding guide exists
3. **Verification Checkpoints**: Need MANDATORY VERIFICATION after all file operations
4. **Bash Block Model**: Verify `set +H` present in all bash blocks and all 6 libraries re-sourced

### Plan 637 Gaps

Based on review of spec 637 context:

1. **Standard 0.5 Compliance**: Agent behavioral files need imperative language transformation (YOU MUST vs "I am")
2. **Standard 12 Compliance**: Verify structural templates inline, behavioral content referenced from agent files
3. **Fallback Mechanisms**: Ensure fallbacks DETECT errors (not create placeholder files)
4. **State Persistence**: Verify GitHub Actions pattern (init → load → append) implemented correctly

## Cross-References

### Related Standards Documentation
- [Command Architecture Standards](../../reference/command_architecture_standards.md) - Complete 14 standards with enforcement patterns
- [State-Based Orchestration Overview](../../architecture/state-based-orchestration-overview.md) - Complete architecture reference
- [Bash Block Execution Model](../../concepts/bash-block-execution-model.md) - Subprocess isolation patterns
- [Verification and Fallback Pattern](../../concepts/patterns/verification-fallback.md) - File creation reliability pattern
- [Context Management Pattern](../../concepts/patterns/context-management.md) - Token usage optimization techniques

### Developer Guides
- [Command Development Guide](../../guides/command-development-guide.md) - Creating and maintaining slash commands
- [State Machine Migration Guide](../../guides/state-machine-migration-guide.md) - Migrating from phase-based to state-based
- [Coordinate Command Guide](../../guides/coordinate-command-guide.md) - Real-world usage of these patterns

### Implementation References
- [Imperative Language Guide](../../guides/imperative-language-guide.md) - Standard 0 transformation rules
- [Behavioral Injection Pattern](../../concepts/patterns/behavioral-injection.md) - Standard 11 anti-pattern documentation
- [Executable/Documentation Separation Pattern](../../concepts/patterns/executable-documentation-separation.md) - Standard 14 complete pattern

### Validation Tools
- `.claude/tests/validate_executable_doc_separation.sh` - Automated Standard 14 validation
- `.claude/lib/validate-agent-invocation-pattern.sh` - Standard 11 anti-pattern detection
- `.claude/tests/test_orchestration_commands.sh` - Comprehensive orchestration testing

## Implementation Guidance

### For Plan 636 (Coordinate Improvements)

**Priority 1: Standard 11 Compliance**
1. Review all Task invocations in coordinate.md
2. Add "**EXECUTE NOW**: USE the Task tool..." before each invocation
3. Remove any code block wrappers (` ```yaml`)
4. Verify completion signals required (REPORT_CREATED, etc.)

**Priority 2: Verification Checkpoints**
1. Add MANDATORY VERIFICATION after all file operations
2. Use pattern: `[ -f "$FILE_PATH" ] || { echo "CRITICAL: File missing"; exit 1; }`
3. Log verification results
4. Terminate workflow on verification failure (fail-fast)

**Priority 3: Bash Block Model Compliance**
1. Add `set +H` at start of every bash block
2. Verify all 6 libraries re-sourced (including unified-logger.sh)
3. Use state-persistence.sh for cross-block state
4. Cleanup traps only in final completion function

**Priority 4: Context Management**
1. Extract metadata from agent outputs
2. Prune completed phase data
3. Target: <30% context usage across workflow

### For Plan 637 (Coordinate Improvements - Error Handling)

**Priority 1: Standard 0.5 Compliance**
1. Transform agent behavioral files to imperative language
2. Replace "I am" with "YOU MUST perform"
3. Add STEP dependencies (REQUIRED BEFORE STEP N+1)
4. Mark file creation as PRIMARY OBLIGATION

**Priority 2: Fallback Pattern Alignment**
1. Ensure fallbacks DETECT errors (not create placeholders)
2. Add clear diagnostics showing failure point
3. Terminate workflow with troubleshooting steps
4. No silent degradation

**Priority 3: State Persistence Integration**
1. Implement GitHub Actions pattern (init → load → append)
2. Use selective persistence (7 critical items)
3. Graceful degradation to stateless recalculation

**Priority 4: Error State Tracking**
1. Use Checkpoint Schema V2.0 error_state section
2. Track retry count (max 2 retries per state)
3. Log error details for diagnostics

## Success Criteria

Both plans achieve compliance when:

1. **Standard 11**: All agent invocations use imperative pattern (>90% delegation rate)
2. **Standard 14**: Executable file <1,200 lines, comprehensive guide exists
3. **Verification**: 100% file creation success rate (10/10 tests)
4. **Bash Block Model**: All 6 libraries re-sourced in every block, set +H present
5. **State Persistence**: GitHub Actions pattern implemented, 67% performance improvement
6. **Context Management**: <30% context usage across entire workflow
7. **Fallback Pattern**: Verification checkpoints present, fail-fast on missing files

## Validation Checklist

Use this checklist to validate compliance:

### Standard 0 (Execution Enforcement)
- [ ] Critical steps use imperative language (YOU MUST, EXECUTE NOW, MANDATORY)
- [ ] MANDATORY VERIFICATION checkpoints after all file operations
- [ ] Fallback mechanisms DETECT errors (not create placeholders)
- [ ] Agent prompts marked "THIS EXACT TEMPLATE (No modifications)"
- [ ] Checkpoint reporting at major milestones

### Standard 11 (Imperative Agent Invocation)
- [ ] All Task invocations preceded by "**EXECUTE NOW**: USE the Task tool..."
- [ ] No code block wrappers around Task invocations
- [ ] Agent behavioral files directly referenced
- [ ] Completion signals required (REPORT_CREATED, etc.)
- [ ] No "Example" prefixes or documentation context

### Standard 12 (Structural vs Behavioral Separation)
- [ ] Structural templates inline (Task syntax, bash blocks, JSON schemas)
- [ ] Behavioral content referenced from agent files (no duplication)
- [ ] 90% code reduction per agent invocation achieved

### Standard 13 (Project Directory Detection)
- [ ] CLAUDE_PROJECT_DIR pattern used (not ${BASH_SOURCE[0]})
- [ ] Enhanced error diagnostics for library sourcing failures

### Standard 14 (Executable/Documentation Separation)
- [ ] Executable file <1,200 lines (orchestrators) or <250 lines (simple commands)
- [ ] Comprehensive command guide exists
- [ ] Bidirectional cross-references present

### Bash Block Execution Model
- [ ] set +H at start of every bash block
- [ ] All 6 libraries re-sourced in each block
- [ ] unified-logger.sh included for emit_progress and display_brief_summary
- [ ] State persistence via state-persistence.sh
- [ ] Fixed semantic filenames (not $$-based)
- [ ] Cleanup traps only in final completion function

### Verification and Fallback Pattern
- [ ] Path pre-calculation before execution
- [ ] MANDATORY VERIFICATION after all file operations
- [ ] Fallback mechanisms DETECT errors (fail-fast)
- [ ] 100% file creation success rate achieved

### Context Management
- [ ] Metadata extraction implemented
- [ ] Context pruning after completed phases
- [ ] Forward message pattern (no re-summarization)
- [ ] Layered context architecture
- [ ] <30% context usage target achieved

## References

### Files Analyzed
1. `.claude/docs/reference/command_architecture_standards.md` (2,325 lines)
2. `.claude/docs/architecture/state-based-orchestration-overview.md` (1,749 lines)
3. `.claude/docs/concepts/bash-block-execution-model.md` (642 lines)
4. `.claude/docs/concepts/patterns/verification-fallback.md` (448 lines)
5. `.claude/docs/concepts/patterns/context-management.md` (292 lines)

### External Sources
- Spec 438 (2025-10-24): /supervise agent delegation fix
- Spec 495 (2025-10-27): /coordinate and /research agent delegation failures
- Spec 057 (2025-10-27): /supervise robustness improvements and fail-fast error handling
- Spec 620: Bash history expansion errors and subprocess isolation discovery
- Spec 630: State persistence architecture fixes
- Plan 077: Verification and fallback pattern validation

### Documentation Cross-Links
- [Imperative Language Guide](../../guides/imperative-language-guide.md)
- [Behavioral Injection Pattern](../../concepts/patterns/behavioral-injection.md)
- [Executable/Documentation Separation Pattern](../../concepts/patterns/executable-documentation-separation.md)
- [State Machine Migration Guide](../../guides/state-machine-migration-guide.md)
- [Coordinate Command Guide](../../guides/coordinate-command-guide.md)

## Metadata Summary
- **Standards Reviewed**: 5 major architectural standards (14 sub-standards total)
- **Patterns Identified**: 4 critical design patterns
- **Execution Models**: 2 fundamental models (Command Architecture, Bash Block)
- **Files Analyzed**: 5 comprehensive documentation files (5,456 total lines)
- **Compliance Gaps**: 8 identified (4 per plan)
- **Validation Checklist Items**: 34 total checks
- **Success Criteria**: 7 measurable targets
