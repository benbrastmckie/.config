# Documentation Standards Review

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Documentation Standards in .claude/docs/
- **Report Type**: codebase analysis
- **Complexity Level**: 3

## Executive Summary

The `.claude/docs/` directory establishes comprehensive standards through the Diataxis framework (reference, guides, concepts, workflows) with 16 architectural standards and 11 core patterns. Key conventions include: topic-based artifact organization in `specs/NNN_topic/`, imperative execution language (MUST/WILL/SHALL), behavioral injection for agent invocation, executable/documentation separation (<250 lines commands), and timeless writing (no historical markers). Standards emphasize explicit state machines, verified transitions, and 100% file creation reliability through MANDATORY VERIFICATION checkpoints.

## Findings

### 1. Documentation Organization Framework

**Diataxis Structure** (/home/benjamin/.config/.claude/docs/README.md:7-13):
- **Reference**: Information-oriented quick lookup (14 files)
- **Guides**: Task-focused how-to guides (19+ files)
- **Concepts**: Understanding-oriented explanations (5 files + patterns/)
- **Workflows**: Learning-oriented step-by-step tutorials (7 files)

**Purpose**: Enables developers to quickly find documentation based on immediate need (lookup vs problem-solving vs understanding vs learning).

**Content Ownership**: Single source of truth principle
- Patterns catalog (`concepts/patterns/`) is authoritative for architectural patterns
- Command Reference is authoritative for command syntax
- Agent Reference is authoritative for agent capabilities
- Guides cross-reference authoritative sources rather than duplicating

### 2. Command Architecture Standards (16 Standards)

**Location**: /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md

**Standard 0: Execution Enforcement** (lines 51-465)
- **Imperative vs Descriptive**: Commands use "YOU MUST", "EXECUTE NOW", "MANDATORY" (not "should/may/can")
- **Verification Checkpoints**: MANDATORY VERIFICATION blocks after critical operations
- **Fallback Mechanisms**: Guarantee file creation even if agents don't comply
- **Phase 0 Requirement**: Orchestrators pre-calculate all artifact paths before invoking agents

**Standard 11: Imperative Agent Invocation** (lines 1175-1354)
- **Required Elements**: Imperative instruction + agent behavioral file reference + no code block wrappers
- **Anti-Pattern**: Documentation-only YAML blocks (0% delegation rate)
- **Pattern**: "**EXECUTE NOW**: USE the Task tool to invoke..." (not "Example invocation:")
- **Historical Context**: Fixed 0% → >90% delegation rate in Specs 438, 495, 057

**Standard 12: Structural vs Behavioral Separation** (lines 1356-1501)
- **Inline**: Task syntax, bash blocks, JSON schemas, verification checkpoints, critical warnings
- **Referenced**: Agent STEP sequences, file creation workflows, output format specs
- **Rationale**: 50-67% maintenance burden reduction, 90% code reduction per invocation
- **Enforcement**: <5 STEP instructions in commands, zero PRIMARY OBLIGATION occurrences

**Standard 14: Executable/Documentation Separation** (lines 1581-1737)
- **Pattern**: Two-file architecture (executable + guide)
- **Executable**: <250 lines (simple), <1,200 lines (orchestrators), bash blocks only
- **Guide**: Unlimited length, architecture/examples/troubleshooting
- **Results**: 70% average reduction, 0% meta-confusion (was 75%), 100% execution success

### 3. Directory Protocols and Organization

**Topic-Based Structure** (/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md:40-51):
```
specs/{NNN_topic}/
├── plans/          # Implementation plans (gitignored)
├── reports/        # Research reports (gitignored)
├── summaries/      # Implementation summaries (gitignored)
├── debug/          # Debug reports (COMMITTED to git)
├── scripts/        # Investigation scripts (gitignored, temporary)
├── outputs/        # Test outputs (gitignored, temporary)
├── artifacts/      # Operation artifacts (gitignored, 30-day retention)
└── backups/        # Backups (gitignored, 30-day retention)
```

**Artifact Lifecycle** (lines 447-535):
- **Core artifacts** (reports/plans/summaries): Preserved indefinitely
- **Debug reports**: Permanent (project history, issue tracking)
- **Investigation scripts**: 0 days (removed after workflow)
- **Test outputs**: 0 days (removed after validation)
- **Operational artifacts**: 30 days configurable retention

**Metadata-Only Passing** (lines 146-174):
- **Context Reduction**: 95% (5000 tokens → 250 tokens per report)
- **Utilities**: `extract_report_metadata()`, `extract_plan_metadata()`, `load_metadata_on_demand()`
- **Pattern**: Pass path + summary + key findings (not full content)

### 4. Writing Standards and Philosophy

**Location**: /home/benjamin/.config/.claude/docs/concepts/writing-standards.md

**Timeless Writing Principles** (lines 67-76):
- **Write**: Present-focused current state descriptions
- **Avoid**: Past comparisons, version markers, temporal phrases
- **Ban**: "(New)", "(Old)", "(Updated)", "previously", "recently", "now supports"
- **Purpose**: Documentation describes "what system does" not "how it changed"

**Banned Patterns** (lines 79-190):
- **Temporal Markers**: (New), (Old), (Updated), (Deprecated)
- **Temporal Phrases**: "previously", "recently", "now supports", "used to"
- **Migration Language**: "migrated to", "backward compatibility", "breaking change"
- **Version References**: "v1.0", "since version", "introduced in"

**Clean-Break Refactors** (lines 23-30):
- Prioritize coherence over compatibility
- Clean design preferred over backward compatibility
- Exception: Command/agent files are AI prompts (special refactoring rules)

### 5. State-Based Orchestration Architecture

**Location**: /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md

**Core Achievements** (lines 29-46):
- **Code Reduction**: 48.9% (3,420 → 1,748 lines across 3 orchestrators)
- **Performance**: 67% faster state operations, 95.6% context reduction
- **Architecture**: Explicit states replace phase numbers, validated transitions

**State Machine Principles** (lines 88-145):
- **Explicit Over Implicit**: Named states ("research") not numbers (1)
- **Validated Transitions**: Transition table prevents invalid state changes
- **Centralized Lifecycle**: Single state machine library owns all operations
- **Selective Persistence**: File-based state when justified, stateless recalculation otherwise

### 6. Architectural Patterns Catalog

**Location**: /home/benjamin/.config/.claude/docs/concepts/patterns/README.md

**11 Core Patterns**:
1. **Behavioral Injection**: Commands reference agent files (not inline duplication)
2. **Hierarchical Supervision**: Multi-level agent coordination (95%+ context reduction)
3. **Forward Message**: Direct subagent response passing
4. **Metadata Extraction**: 95-99% context reduction via summaries
5. **Context Management**: <30% context usage techniques
6. **Verification/Fallback**: 100% file creation via checkpoints
7. **Checkpoint Recovery**: State preservation/restoration
8. **Parallel Execution**: Wave-based concurrent execution (40-60% time savings)
9. **Workflow Scope Detection**: Conditional phase execution
10. **LLM Classification**: 98%+ accuracy with automatic fallback
11. **Executable/Documentation Separation**: Lean executables (<250 lines)

**Performance Metrics** (lines 119-127):
- File Creation Rate: 100%
- Context Reduction: 95-99%
- Time Savings: 40-60% (parallel execution)
- Context Usage: <30% throughout workflows
- Classification Accuracy: 97%+ (vs 92% regex-only)

### 7. Planning and Implementation Standards

**Plan Structure Levels** (/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md:798-826):
- **Level 0**: Single file, all phases inline (ALL plans start here)
- **Level 1**: Phase expansion (created on-demand via `/expand-phase`)
- **Level 2**: Stage expansion (created on-demand via `/expand-stage`)
- **Progressive Expansion**: Structure grows organically based on implementation needs

**Phase Dependencies** (lines 832-881):
- **Syntax**: `Dependencies: []` or `Dependencies: [1, 2, 3]`
- **Wave-Based Execution**: Kahn's algorithm for topological sorting
- **Time Savings**: 40-60% through parallelization of independent phases
- **Rules**: Forward dependencies only, circular detection, self-dependencies invalid

### 8. Code Standards and Conventions

**Location**: /home/benjamin/.config/.claude/docs/reference/code-standards.md

**General Principles** (lines 5-10):
- Indentation: 2 spaces, expandtab
- Line length: ~100 characters (soft limit)
- Naming: snake_case (variables/functions), PascalCase (module tables)
- Error Handling: Defensive programming with structured error messages (WHICH/WHAT/WHERE)
- Documentation: Every directory requires README.md
- Character Encoding: UTF-8 only, no emojis in file content

**Link Conventions** (lines 56-83):
- All internal markdown links use relative paths
- Prohibited: Absolute filesystem paths, repository-relative without base
- Validation: `.claude/scripts/validate-links-quick.sh` before committing
- Template placeholders allowed: `{variable}`, `NNN_topic`, `$ENV_VAR`

### 9. Directory Organization Standards

**Location**: /home/benjamin/.config/.claude/docs/concepts/directory-organization.md

**Directory Structure** (lines 10-20):
```
.claude/
├── scripts/        # Standalone CLI tools (validate, fix, migrate)
├── lib/            # Sourced function libraries (parsing, error handling)
├── commands/       # Slash command definitions
│   └── templates/  # Plan templates (YAML)
├── agents/         # Specialized AI assistant definitions
│   └── templates/  # Agent behavioral templates
├── docs/           # Integration guides and standards
└── tests/          # Test suites for system validation
```

**File Placement Decision Matrix** (lines 155-164):
- Standalone executable + CLI arguments → `scripts/`
- Sourced by other code + reusable function → `lib/`
- User-facing command + complete workflow → `commands/`
- AI agent behavioral → `agents/`

**Directory README Requirements** (lines 206-241):
- Purpose (1-2 sentences)
- Characteristics (bulleted list)
- Examples (3-5 concrete examples)
- When to Use (decision criteria)
- Documentation Links (cross-references)

### 10. Development Workflow Integration

**Location**: /home/benjamin/.config/.claude/docs/concepts/development-workflow.md

**Spec Updater Integration** (lines 11-40):
- **Agent Role**: Manages artifacts in topic-based directories
- **Responsibilities**: Creates artifacts, maintains cross-references, manages lifecycle
- **Checklist**: Included in all plan templates
- **Gitignore**: Ensures debug/ committed, others ignored

**Plan Hierarchy Updates** (lines 92-102):
- **Library**: `.claude/lib/checkbox-utils.sh`
- **Functions**: `update_checkbox()`, `propagate_checkbox_update()`, `mark_phase_complete()`
- **Integration**: `/implement` invokes spec-updater after git commit success
- **Propagation**: L2 → L1 → L0 checkbox synchronization

## Recommendations

### 1. New Orchestrator Command Pattern

**Apply State-Based Architecture**:
- Use workflow-state-machine.sh for explicit state enumeration
- Implement validated transitions via `sm_transition()`
- Follow Standard 15 library sourcing order (state-persistence before error-handling)
- Pre-calculate artifact paths in Phase 0 before agent invocations

**Example Template** (from coordinate.md):
```bash
# Phase 0: Pre-Flight Validation
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

if ! sm_init "$WORKFLOW_DESC" "command-name" 2>&1; then
  handle_state_error "State machine initialization failed" 1
fi
```

### 2. File Creation Enforcement Pattern

**Implement MANDATORY VERIFICATION**:
- Pre-calculate file paths before agent invocation (Phase 0)
- Inject paths into agent prompts (behavioral injection)
- Verify file existence after agent completes
- Use fail-fast diagnostics (not silent fallback creation)

**Pattern** (Command Architecture Standards Standard 0):
```bash
# Pre-calculate path
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "topic" "")

# Invoke agent with path
Task {
  prompt: "
    Output Path: $REPORT_PATH
    Return: REPORT_CREATED: $REPORT_PATH
  "
}

# Verify creation
if [ ! -f "$REPORT_PATH" ]; then
  handle_state_error "CRITICAL: Report missing at $REPORT_PATH" 1
fi
```

### 3. Documentation Structure for New Commands

**Use Two-File Architecture** (Standard 14):
1. **Executable** (`.claude/commands/new-command.md`):
   - Target: <250 lines (simple), <1,200 lines (orchestrators)
   - Content: Bash blocks, phase markers, minimal comments
   - Template: `.claude/docs/guides/_template-executable-command.md`

2. **Guide** (`.claude/docs/guides/new-command-command-guide.md`):
   - Size: Unlimited
   - Content: Architecture, examples, troubleshooting
   - Template: `.claude/docs/guides/_template-command-guide.md`

### 4. Context Management Strategy

**Apply Metadata-Only Passing**:
- Extract metadata (title, summary, key findings) from reports
- Pass 250 tokens instead of 5000 tokens (95% reduction)
- Use `extract_report_metadata()` and `extract_plan_metadata()`
- Allow selective full content loading via Read tool

**Hierarchical Supervision** (for 5+ agents):
- Research supervisor: Coordinates 2-4 research agents (95.6% context reduction)
- Implementation supervisor: Manages wave-based execution (53% time savings)
- Testing supervisor: Sequential lifecycle coordination

### 5. Artifact Organization Compliance

**Topic-Based Structure**:
- Create `specs/NNN_topic/` with 8 standard subdirectories
- Use lazy directory creation (only when files written)
- Ensure gitignore compliance (debug/ committed, others ignored)
- Apply retention policies (0 days: scripts/outputs, 30 days: artifacts/backups, indefinite: core)

**Validation**:
```bash
# Verify gitignore compliance
git check-ignore -v specs/NNN_topic/debug/001_issue.md  # Should NOT be ignored
git check-ignore -v specs/NNN_topic/reports/001_research.md  # Should be ignored
```

### 6. Standards Integration Checklist

**Before Implementing New Orchestrator**:
- [ ] Review State-Based Orchestration Overview
- [ ] Study coordinate.md as reference implementation
- [ ] Apply 16 Command Architecture Standards
- [ ] Use behavioral injection (not inline agent guidelines)
- [ ] Implement imperative agent invocations (Standard 11)
- [ ] Separate executable (<1,200 lines) from guide (unlimited)
- [ ] Pre-calculate paths in Phase 0
- [ ] Add MANDATORY VERIFICATION checkpoints
- [ ] Follow library sourcing order (Standard 15)
- [ ] Test with all workflow scopes

## References

### Core Documentation Standards
- /home/benjamin/.config/.claude/docs/README.md (Diataxis framework overview)
- /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md (16 standards)
- /home/benjamin/.config/.claude/docs/concepts/writing-standards.md (timeless writing principles)
- /home/benjamin/.config/.claude/docs/reference/code-standards.md (general coding conventions)

### Directory Protocols
- /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md (topic-based structure)
- /home/benjamin/.config/.claude/docs/concepts/directory-organization.md (file placement rules)

### Architectural Patterns
- /home/benjamin/.config/.claude/docs/concepts/patterns/README.md (11 core patterns catalog)
- /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md (state machine architecture)

### Development Workflow
- /home/benjamin/.config/.claude/docs/concepts/development-workflow.md (spec updater integration)
- /home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md (progressive plan structures)

### Command Guides
- /home/benjamin/.config/.claude/docs/guides/coordinate-command-index.md (reference implementation)
- /home/benjamin/.config/.claude/docs/guides/_template-executable-command.md (56-line template)
- /home/benjamin/.config/.claude/docs/guides/_template-command-guide.md (171-line template)

### Validation Tools
- /home/benjamin/.config/.claude/scripts/validate-links-quick.sh (link validation)
- /home/benjamin/.config/.claude/tests/validate_executable_doc_separation.sh (Standard 14 compliance)
