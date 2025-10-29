# Claude Code Orchestrator Command Best Practices and Design Patterns

## Metadata
- **Date**: 2025-10-29
- **Agent**: research-specialist
- **Topic**: Claude Code orchestrator command best practices and design patterns
- **Report Type**: best practices
- **Complexity Level**: 3

## Executive Summary

This report synthesizes architectural patterns and best practices for Claude Code orchestrator commands (/coordinate, /orchestrate, /supervise), derived from analysis of existing documentation, command implementations, and pattern libraries. Key findings include: (1) Phase 0 path pre-calculation achieves 85% token reduction and 25x speedup, (2) behavioral injection pattern enables 90% context reduction per agent invocation while maintaining 100% file creation reliability, (3) wave-based parallel execution delivers 40-60% time savings, (4) fail-fast error handling with 5-component diagnostics exposes configuration errors immediately, and (5) concise verification formatting reduces context usage by 90% while preserving full diagnostic capability. Commands following these patterns consistently achieve <30% context usage throughout 7-phase workflows.

## Findings

### 1. The Unified 7-Phase Framework

**Source**: orchestration-best-practices.md (lines 141-161)

All production orchestration commands follow a standardized 7-phase workflow structure:

```
Phase 0: Location Detection (path pre-calculation)
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

**Context Budget Allocation**:
- Phase 0: 500-1,000 tokens (4%)
- Phase 1: 600-1,200 tokens (6% - metadata from 2-4 agents)
- Phase 2: 800-1,200 tokens (5%)
- Phase 3: 1,500-2,000 tokens (8%)
- Phase 4-7: 200-500 tokens each (2% each, conditional phases may be 0%)
- **Total Target**: <21% context usage

### 2. Phase 0 Optimization: Path Pre-Calculation (MANDATORY)

**Source**: orchestration-best-practices.md (lines 172-260), unified-location-detection.sh library

**Performance Breakthrough**:
- Token reduction: 85% (75,600 → 11,000 tokens)
- Speed improvement: 25x faster (25.2s → <1s)
- Eliminates agent-based location detection entirely

**Implementation Pattern**:

```bash
# Source unified location detection library
source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"

# Perform location detection
LOCATION_JSON=$(perform_location_detection "<workflow_description>")

# Extract paths
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
PLANS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.plans')

# MANDATORY VERIFICATION
if [ ! -d "$TOPIC_PATH" ]; then
  echo "ERROR: Location detection failed"
  exit 1
fi

echo "LOCATION_COMPLETE: $TOPIC_PATH"
```

**Lazy Directory Creation**: Only create artifact directories when agents successfully produce output, preventing directory pollution on failures.

**Anti-Pattern**: Agent-based location detection costs 75,600 tokens and 25 seconds. Never invoke agents for path calculation.

### 3. Behavioral Injection Pattern

**Source**: behavioral-injection.md (lines 1-258), command_architecture_standards.md (lines 1127-1398)

**Core Principle**: Commands inject context into agents via explicit path parameters, not by invoking other commands via SlashCommand tool.

**Benefits**:
- 90% context reduction per agent invocation (150 lines → 15 lines)
- 100% file creation reliability through explicit path injection
- Single source of truth for agent guidelines (no duplication)
- Eliminates maintenance burden from synchronized templates

**Correct Pattern** - Context Injection Only:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: OAuth 2.0 authentication patterns
    - Report Path: /absolute/path/to/report.md
    - Project Standards: /path/to/CLAUDE.md
    - Complexity Level: 3

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: /absolute/path/to/report.md
  "
}
```

**Anti-Pattern** - Inline Behavioral Duplication:

❌ WRONG: Duplicating 646 lines of research-specialist.md guidelines inline (creates maintenance burden, violates single source of truth)

**Distinction - Structural Templates vs Behavioral Content**:

**MUST remain inline** (structural templates):
- Task invocation syntax: `Task { subagent_type, description, prompt }`
- Bash execution blocks: `**EXECUTE NOW**: bash commands`
- JSON schemas and data structure definitions
- Verification checkpoints: `**MANDATORY VERIFICATION**: checks`
- Critical warnings: `**CRITICAL**: constraints`

**MUST be referenced, not duplicated** (behavioral content):
- Agent STEP sequences: `STEP 1/2/3` procedural instructions
- File creation workflows: `PRIMARY OBLIGATION` blocks
- Agent verification steps: Agent-internal quality checks
- Output format specifications: Templates for agent responses

### 4. Imperative Agent Invocation Pattern (Standard 11)

**Source**: command_architecture_standards.md (lines 1127-1307)

**Problem**: Documentation-only YAML blocks create 0% agent delegation rate because Claude interprets them as syntax examples, not executable instructions.

**Required Elements for ALL agent invocations**:

1. **Imperative Instruction**: `**EXECUTE NOW**: USE the Task tool to invoke...`
2. **Agent Behavioral File Reference**: `Read and follow: .claude/agents/[name].md`
3. **No Code Block Wrappers**: Task invocations NOT wrapped in ` ```yaml` fences
4. **No "Example" Prefixes**: Remove documentation context markers
5. **Completion Signal**: Agent returns explicit confirmation (e.g., `REPORT_CREATED: ${PATH}`)

**Correct Pattern**:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: "..."
}
```

**Anti-Pattern**:

```markdown
❌ WRONG - Documentation-only block:

Example agent invocation:

```yaml
Task {
  subagent_type: "general-purpose"
  ...
}
```

This will never execute (code fence prevents execution).
```

**Performance Metrics** (from Specs 438, 495, 057):
- Agent delegation rate: 0% → >90% after applying Standard 11
- File creation reliability: Variable → 100% with explicit path injection
- Context reduction: 90% per invocation (behavioral injection)
- Bootstrap reliability: 100% (fail-fast exposes configuration errors)

### 5. Metadata Extraction and Forward Message Pattern

**Source**: orchestration-best-practices.md (lines 264-386), metadata-extraction.sh library

**Context Reduction**: 95-99% per report (5,000 tokens → 250 tokens)

**Implementation**:

```bash
# Source metadata extraction library
source "${CLAUDE_CONFIG}/.claude/lib/metadata-extraction.sh"

# Extract metadata from research report
METADATA=$(extract_report_metadata "$REPORT_PATH")

# Forward metadata directly (NO re-summarization)
echo "**Research Context** (metadata only):"
echo "$METADATA"
```

**Forward Message Pattern Principle**: Pass subagent responses directly without re-summarization.

✅ CORRECT:
```markdown
**RESEARCH CONTEXT** (metadata only):
{PASTE metadata exactly as extracted in Phase 1}
```

❌ WRONG:
```markdown
**RESEARCH CONTEXT**:
Based on the research, I found that... (re-summarization adds context bloat)
```

**Metadata Size**: 200-300 tokens per report (title + 50-word summary + key findings)

### 6. Wave-Based Parallel Execution

**Source**: orchestration-best-practices.md (lines 502-616), coordinate.md (lines 186-244), dependency-analyzer.sh library

**Performance Impact**: 40-60% time savings through parallel implementation of independent phases

**How It Works**:

1. **Dependency Analysis**: Parse plan for `dependencies: [N, M]` in each phase
2. **Wave Calculation**: Group phases using Kahn's topological sort algorithm
3. **Parallel Execution**: Execute all phases within wave simultaneously
4. **Wave Checkpointing**: Save state after each wave completes

**Example**:

```
8-phase plan with dependencies:
  Phase 1: dependencies: []
  Phase 2: dependencies: []
  Phase 3: dependencies: [1]
  Phase 4: dependencies: [1]
  Phase 5: dependencies: [2]
  Phase 6: dependencies: [3, 4]
  Phase 7: dependencies: [5]
  Phase 8: dependencies: [6, 7]

Wave Calculation:
  Wave 1: [1, 2]          (2 phases parallel)
  Wave 2: [3, 4, 5]       (3 phases parallel)
  Wave 3: [6, 7]          (2 phases parallel)
  Wave 4: [8]             (1 phase)

Time Savings:
  Sequential: 8 phases × avg_time = 8T
  Wave-based: 4 waves × avg_time = 4T
  Savings: 50%
```

**Integration**:

```bash
# Source dependency analyzer
source "${CLAUDE_CONFIG}/.claude/lib/dependency-analyzer.sh"

# Analyze plan dependencies
WAVES=$(analyze_dependencies_kahn "$PLAN_PATH")

# Execute waves sequentially, phases within wave in parallel
for wave in $WAVES; do
  # Invoke implementation agents in parallel (single Task call)
  # Wait for wave completion
  # Prune completed wave context
done
```

### 7. Fail-Fast Error Handling with 5-Component Diagnostics

**Source**: orchestration-best-practices.md (lines 1146-1219), coordinate.md (lines 269-311)

**Philosophy**: "One clear execution path, fail fast with full context"

**Key Behaviors**:
- NO retries (single execution attempt)
- NO fallbacks (report error and exit)
- Clear diagnostics (every error shows what failed and why)
- Debugging guidance (steps to diagnose)
- Exception: Partial research success (≥50% agents succeed in Phase 1 only)

**5-Component Error Message Standard**:

1. **What Failed**: Specific operation (e.g., "unified-location-detection.sh library load failed")
2. **Expected State**: What should have happened
3. **Diagnostic Commands**: Exact commands to investigate (e.g., `ls -la ${CLAUDE_CONFIG}/.claude/lib/`)
4. **Context**: Why this is required
5. **Action**: Steps to resolve

**Example**:

```bash
if ! source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh" 2>/dev/null; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "ERROR: Failed to load unified-location-detection.sh library"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "**What failed**: Library sourcing"
  echo "**Expected**: Library should exist at ${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"
  echo "**Diagnostic**: Run: ls -la ${CLAUDE_CONFIG}/.claude/lib/"
  echo "**Context**: Required for Phase 0 path pre-calculation (85% token reduction)"
  echo "**Action**: Verify installation: git status .claude/lib/ | grep unified-location-detection"
  echo ""
  exit 1
fi
```

**Fail-Fast vs Verification Checkpoints**:

| Situation | Approach | Rationale |
|-----------|----------|-----------|
| Bootstrap library loading | Fail-Fast | Configuration error - cannot proceed |
| File creation (agent output) | Verification + Fallback | Transient error - agent may retry |
| Directory creation | Verification + Fallback | Transient error - can retry |
| Function availability | Fail-Fast | Configuration error - library not sourced |

### 8. Concise Verification Pattern

**Source**: orchestration-best-practices.md (lines 952-1014)

**Philosophy**: Silent on success (1-2 lines), verbose on failure (full diagnostics)

**Success Format** (90% token reduction):
```
Verifying research reports (3): ✓✓✓ (all passed)
```

**Failure Format** (comprehensive diagnostics):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VERIFICATION FAILED: Research agent did not create report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**What failed**: Report file creation
**Expected**: Report should exist at /path/to/report.md
**Diagnostic**: Check agent output above for errors
**Context**: Required for metadata extraction in Phase 1
**Action**: Review agent prompt for path injection, verify write permissions
```

**Implementation**:

```bash
verify_file_created() {
  local file_path="$1"

  if [ -f "$file_path" ]; then
    echo -n "✓"  # Silent success
  else
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "VERIFICATION FAILED: File not created"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "**What failed**: File creation"
    echo "**Expected**: File should exist at $file_path"
    echo "**Diagnostic**: Check agent output for errors"
    echo "**Context**: Required for workflow continuation"
    echo "**Action**: Review agent prompt, verify permissions"
    echo ""
    return 1
  fi
}

# Usage
echo -n "Verifying research reports ($COUNT): "
for report in "${REPORT_PATHS[@]}"; do
  verify_file_created "$report"
done
echo " (all passed)"
```

**Metrics**:
- Success output: 50+ lines → 1-2 lines (≥90% reduction)
- Token reduction: ≥3,150 tokens per workflow
- File creation reliability: >95% through proper agent invocation

### 9. Output Formatting and Context Management

**Source**: orchestration-best-practices.md (lines 862-1143)

**Architecture**: "Libraries calculate, commands communicate" (separation of concerns)

**Library Silence Pattern**:

```bash
# Library code - SILENT
detect_workflow_scope() {
  # Performs logic
  # NO echo statements except errors to stderr
  echo "$WORKFLOW_SCOPE"  # Return value only
}

# Command code - COMMUNICATES
WORKFLOW_SCOPE=$(detect_workflow_scope "$DESC")
echo "Workflow scope: $WORKFLOW_SCOPE"  # User-facing output
```

**Benefits**:
- Library output reduced: 30+ lines → 0 lines (100% reduction)
- Commands control all user-facing output
- Context savings: ~400 tokens per workflow

**Workflow Scope Detection Format** (8-12 line phase execution report):

```
Workflow scope: research-and-plan

Phases to execute:
  ✓ Phase 0: Location detection
  ✓ Phase 1: Research (2-4 parallel agents)
  ✓ Phase 2: Planning
  ✗ Phase 3: Implementation (skipped)
  ✗ Phase 4: Testing (skipped)
  ✗ Phase 5: Debugging (skipped)
  ✗ Phase 6: Documentation (skipped)
  ✓ Phase 7: Summary
```

**Previous format**: 71 lines → **New format**: 10 lines (86% reduction, ~800 tokens saved)

**Standardized Progress Markers**:

```bash
emit_progress() {
  local phase="$1"
  local message="$2"
  echo "PROGRESS: [Phase $phase] - $message"
}

# Usage
emit_progress "0" "Location detection complete"
emit_progress "1" "Research complete: verified 3/3 reports"
emit_progress "2" "Planning complete: 5-phase plan created"
```

**Benefits**:
- Consistent format across all phase transitions
- External tools can parse progress (`grep "PROGRESS:"`)
- Token reduction: ~200 tokens (box-drawing overhead eliminated)

**Simplified Completion Summary** (8 lines):

```
Workflow complete: research-and-plan

Artifacts:
  ✓ 3 research reports
  ✓ 1 implementation plan (5 phases, 8-12 hours estimated)

Next: /implement specs/042_auth/plans/001_oauth_implementation.md
```

**Previous format**: 53 lines → **New format**: 8 lines (85% reduction, ~700 tokens saved)

**Overall Context Reduction**: 50-60% (~5,250 tokens per workflow)

### 10. Context Budget Management

**Source**: orchestration-best-practices.md (lines 1220-1265)

**Target**: 21% total context usage throughout 7-phase workflow

**Layered Architecture**:

| Layer | Purpose | Budget | Percentage |
|-------|---------|--------|------------|
| Layer 1: Permanent | Command prompt, standards | 500-1,000 tokens | 4% |
| Layer 2: Phase-Scoped | Current phase state, wave tracking | 2,000-4,000 tokens | 12% |
| Layer 3: Metadata | Report/plan summaries (200-300 each) | 600-1,200 tokens | 6% |
| Layer 4: Transient | Full agent outputs (pruned immediately) | 0 tokens | 0% |
| **Total** | Full 7-phase workflow | 3,100-6,200 tokens | 21% |

**Aggressive Pruning Policy** (recommended for orchestration):
- Prune full agent outputs immediately after metadata extraction
- Keep only metadata (title + 50-word summary)
- Prune completed wave context before starting next wave
- Retain only phase completion status

**Example 6-Phase Workflow Budget**:

```
Phase 0: 500 tokens (location detection JSON)
Phase 1: 900 tokens (3 research reports × 300 tokens metadata each)
Phase 2: 800 tokens (plan metadata + forward message)
Phase 3: 2,000 tokens (wave tracking, current implementation state)
Phase 4: 400 tokens (test results summary)
Phase 6: 300 tokens (summary metadata)
───────────────────────────────────────────────────
Total: 4,900 tokens = 19.6% of 25,000 token budget
```

### 11. Library Integration

**Source**: orchestration-best-practices.md (lines 1266-1323)

**8 Required Libraries for Full Orchestration**:

```bash
# Phase 0: Location Detection
source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"

# Phase 1: Research
source "${CLAUDE_CONFIG}/.claude/lib/metadata-extraction.sh"

# Phase 2: Planning
source "${CLAUDE_CONFIG}/.claude/lib/complexity-utils.sh"

# Phase 3: Implementation
source "${CLAUDE_CONFIG}/.claude/lib/dependency-analyzer.sh"
source "${CLAUDE_CONFIG}/.claude/lib/context-pruning.sh"

# Phase 4: Testing
source "${CLAUDE_CONFIG}/.claude/lib/workflow-detection.sh"

# Phase 5: Debugging
source "${CLAUDE_CONFIG}/.claude/lib/error-handling.sh"

# All Phases: Checkpoint Management
source "${CLAUDE_CONFIG}/.claude/lib/checkpoint-utils.sh"
```

**Verification Template**:

```bash
REQUIRED_FUNCTIONS=(
  "perform_location_detection"
  "extract_report_metadata"
  "analyze_plan_complexity"
  "analyze_dependencies_kahn"
  "prune_phase_output"
  "should_run_phase"
  "log_error_diagnostic"
  "save_checkpoint"
)

for func in "${REQUIRED_FUNCTIONS[@]}"; do
  if ! declare -f "$func" > /dev/null; then
    echo "ERROR: Required function '$func' not available"
    exit 1
  fi
done
```

### 12. Command Selection and Maturity Status

**Source**: orchestration-best-practices.md (lines 28-138)

**Recommendation**: Use /coordinate for production workflows (stable, tested, recommended)

**Maturity Matrix**:

| Command | Status | Size | Unique Features | Recommendation |
|---------|--------|------|-----------------|----------------|
| **/coordinate** | **Production-Ready** | 2,500-3,000 lines | Wave-based parallel, workflow scope auto-detection | **Default choice** |
| **/orchestrate** | In Development | 5,438 lines | PR automation, progress dashboard, metrics tracking | Experimental features unstable |
| **/supervise** | In Development | 1,939 lines | External documentation ecosystem, minimal reference | Being stabilized |

**Quick Decision Tree**:

```
Need orchestration workflow?
│
├─ Production use or general workflow? ──→ Use /coordinate (recommended)
│
├─ Experimenting with PR automation? ──→ Try /orchestrate (unstable)
│
└─ Need minimal reference example? ──→ Try /supervise (unstable)
```

**Shared Capabilities** (all commands):
- 7-phase workflow
- Behavioral injection pattern
- Fail-fast error handling
- Checkpoint recovery
- Context management (<30%)

**Unique to /coordinate**:
- Wave-based parallel execution (40-60% time savings)
- Workflow scope auto-detection (4 workflow types)
- Concise verification formatting (90% token reduction)
- Pure orchestration architecture (no command chaining)

### 13. Orchestrator vs Executor Role Clarification (Standard 0: Phase 0)

**Source**: command_architecture_standards.md (lines 277-417)

**Problem**: Multi-agent commands that invoke other slash commands create architectural violations:
- Commands calling other commands (e.g., /orchestrate calling /plan, /implement)
- Loss of artifact path control (cannot pre-calculate topic-based paths)
- Context bloat (cannot extract metadata before full content loaded)
- Recursion risk (command → command → command loops)

**Solution**: Distinguish orchestrator and executor roles

**Orchestrator Role** (coordinates workflow):
- Pre-calculates all artifact paths (topic-based organization)
- Invokes specialized subagents via Task tool (NOT SlashCommand)
- Injects complete context into subagents (behavioral injection pattern)
- Verifies artifacts created at expected locations
- Extracts metadata only (95% context reduction)

**Executor Role** (performs atomic operations):
- Receives pre-calculated paths from orchestrator
- Executes specific task using Read/Write/Edit/Bash tools
- Creates artifacts at exact paths provided
- Returns metadata only (not full content)

**Phase 0 Requirement for Orchestrators**:

Every orchestrator command MUST include Phase 0 before invoking any subagents:

```bash
# Determine topic directory
WORKFLOW_DESC="$1"
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESC" ".claude/specs")

# Create subdirectories
mkdir -p "$TOPIC_DIR"/{reports,plans,summaries,debug,scripts,outputs}

# Pre-calculate artifact paths
RESEARCH_REPORT_BASE="$TOPIC_DIR/reports"
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")
SUMMARY_PATH=$(create_topic_artifact "$TOPIC_DIR" "summaries" "workflow_summary" "")

# Export for subagent injection
export TOPIC_DIR RESEARCH_REPORT_BASE PLAN_PATH SUMMARY_PATH
```

**Anti-Pattern to Avoid** (command chaining):

❌ BAD:
```markdown
SlashCommand {
  command: "/plan ${FEATURE_DESCRIPTION}"
}
# Problems: /plan calculates own paths, orchestrator loses control, context bloat
```

✅ GOOD (direct agent invocation):
```markdown
# Phase 0: Pre-calculate plan path
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")

# Phase N: Invoke agent with injected context
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read: .claude/agents/plan-architect.md
    **Plan Output Path**: ${PLAN_PATH}
    **Feature**: ${FEATURE_DESCRIPTION}
}
```

## Recommendations

### 1. Adopt Phase 0 Path Pre-Calculation as Mandatory

**Priority**: Critical

**Implementation**: All orchestration commands must source `unified-location-detection.sh` and call `perform_location_detection()` before any agent invocations.

**Benefits**:
- 85% token reduction (75,600 → 11,000 tokens)
- 25x speed improvement (25.2s → <1s)
- Enables explicit context injection into agents
- Enables lazy directory creation (only when agents produce output)

**Action Items**:
1. Add Phase 0 verification to orchestration command validation scripts
2. Document Phase 0 as non-negotiable requirement in command development guide
3. Create migration guide for commands still using agent-based location detection

### 2. Enforce Behavioral Injection Pattern Consistently

**Priority**: Critical

**Implementation**: All agent invocations must reference behavioral files (`.claude/agents/*.md`) with context injection only, never duplicate behavioral content inline.

**Benefits**:
- 90% context reduction per invocation (150 lines → 15 lines)
- Single source of truth eliminates maintenance burden
- 100% file creation reliability through explicit path injection

**Action Items**:
1. Use `.claude/lib/validate-agent-invocation-pattern.sh` to detect anti-patterns
2. Update all commands violating Standard 11 (imperative agent invocation)
3. Document distinction between structural templates (inline) vs behavioral content (referenced)

### 3. Standardize on Concise Verification Formatting

**Priority**: High

**Implementation**: Adopt "silent success, verbose failure" verification pattern across all orchestration commands.

**Benefits**:
- 90% token reduction on success (50+ lines → 1-2 lines)
- Full diagnostic capability preserved on failures
- Clearer user experience (scan completion at glance)

**Action Items**:
1. Extract `verify_file_created()` pattern to shared library
2. Standardize error message structure (5-component diagnostics)
3. Update existing commands to use concise verification

### 4. Implement Wave-Based Parallel Execution Where Applicable

**Priority**: Medium

**Implementation**: Commands executing multi-phase plans should use `dependency-analyzer.sh` for wave calculation and parallel execution within waves.

**Benefits**:
- 40-60% time savings compared to sequential execution
- No overhead for plans with <3 phases
- Wave-level checkpointing enables resume from wave boundaries

**Action Items**:
1. Add wave-based execution to /orchestrate (currently sequential)
2. Add wave-based execution to /supervise (currently sequential)
3. Document wave calculation algorithm and best practices

### 5. Adopt Fail-Fast Error Handling with 5-Component Diagnostics

**Priority**: High

**Implementation**: Replace retry loops and fallback mechanisms with fail-fast approach and comprehensive diagnostics.

**Benefits**:
- Exposes configuration errors immediately (not hidden by fallbacks)
- Easier to debug (clear failure point, no retry state)
- Faster feedback (immediate failure notification)

**Action Items**:
1. Remove bootstrap fallback mechanisms (replaced with fail-fast in Spec 057)
2. Preserve file creation verification fallbacks (detect transient errors)
3. Standardize 5-component error message format across all commands

### 6. Minimize Command File Size Through Library Integration

**Priority**: Medium

**Implementation**: Extract reusable logic to shared libraries, reference behavioral files instead of duplicating content.

**Benefits**:
- Reduced maintenance burden (single source of truth)
- Clearer command structure (orchestration logic only)
- Consistent behavior across commands

**Action Items**:
1. Identify remaining inline duplication in command files
2. Extract to appropriate libraries or agent behavioral files
3. Target: 2,000-3,000 lines per orchestration command (coordinate.md as reference)

### 7. Document and Enforce Orchestrator vs Executor Role Separation

**Priority**: High

**Implementation**: Clearly distinguish orchestrator commands (coordinate, orchestrate, supervise) from executor agents (research-specialist, plan-architect, etc.).

**Benefits**:
- Prevents command chaining anti-pattern
- Enables hierarchical multi-agent coordination
- Maintains clear separation of concerns

**Action Items**:
1. Add explicit role declaration to all orchestration commands
2. Prohibit SlashCommand usage in orchestrators (use Task tool only)
3. Document role clarification in command architecture standards

## References

### Documentation Files
- `/home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md` (lines 1-1516)
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (lines 1-2030)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` (lines 1-300)
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 1-500)

### Library Files
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`
- `/home/benjamin/.config/.claude/lib/metadata-extraction.sh`
- `/home/benjamin/.config/.claude/lib/dependency-analyzer.sh`
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh`
- `/home/benjamin/.config/.claude/lib/workflow-detection.sh`
- `/home/benjamin/.config/.claude/lib/error-handling.sh`
- `/home/benjamin/.config/.claude/lib/context-pruning.sh`
- `/home/benjamin/.config/.claude/lib/unified-logger.sh`

### Related Patterns
- Metadata Extraction Pattern (95% context reduction)
- Forward Message Pattern (no re-summarization)
- Parallel Execution Pattern (wave-based implementation)
- Verification and Fallback Pattern (fail-fast vs verification)
- Workflow Scope Detection Pattern (conditional phase execution)
- Checkpoint Recovery Pattern (resumable workflows)
- Context Management Pattern (pruning and reduction)

### Implementation Specs
- Spec 438: /supervise agent delegation fix (0% → >90% delegation rate)
- Spec 495: /coordinate and /research agent delegation fixes
- Spec 057: /supervise robustness improvements and fail-fast error handling
- Spec 497: Unified plan for coordinate/supervise/orchestrate improvements
- Spec 508: Unified framework synthesis (7-phase workflow)
- Spec 513: Orchestration command comparison analysis

### Performance Metrics
- Phase 0 optimization: 85% token reduction, 25x speedup
- Behavioral injection: 90% context reduction per invocation
- Wave-based execution: 40-60% time savings
- Concise verification: 90% token reduction on success
- Overall context usage: <30% throughout 7-phase workflows
- File creation reliability: 100% (with mandatory verification checkpoints)
- Agent delegation rate: >90% (with imperative invocation pattern)
