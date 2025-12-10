---
report_type: best_practices
topic: "Context Management and Artifact Passing in Hierarchical Agent Architecture"
findings_count: 6
recommendations_count: 5
---

# Research Report: Context Management and Artifact Passing

## Metadata
- **Date**: 2025-12-10
- **Agent**: research-specialist
- **Topic**: Context Management and Artifact Passing
- **Report Type**: best practices

## Executive Summary

Research reveals six comprehensive patterns for context pollution prevention in hierarchical agent architectures: metadata-only passing (95%+ reduction), hard barrier validation, brief summary format (96% reduction), artifact creation standards, progressive context reduction, and layered context architecture. These patterns enable multi-iteration workflows (10+ iterations vs 3-4 baseline) through aggressive context management, achieving <30% context usage across entire workflow lifecycles.

## Findings

### Finding 1: Metadata-Only Passing Pattern (95% Context Reduction)

**Description**: Coordinators extract brief metadata from subagent artifacts instead of passing full content to primary agents.

**Location**:
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (lines 738-769)
- `/home/benjamin/.config/.claude/agents/research-coordinator.md` (lines 465-598)

**Evidence**:
```markdown
# Traditional Approach (primary agent reads all reports):
3 reports x 2,500 tokens = 7,500 tokens consumed

# Coordinator Approach (metadata-only):
3 reports x 110 tokens metadata = 330 tokens consumed
Context reduction: 95.6%

# Metadata Format
{
  "reports": [
    {
      "path": "/abs/path/to/001-mathlib-group-homomorphism.md",
      "title": "Mathlib Theorems for Group Homomorphism",
      "findings_count": 12,
      "recommendations_count": 5
    }
  ],
  "total_reports": 3,
  "total_findings": 30,
  "total_recommendations": 15
}
```

**Impact**: Enables 10+ coordinator iterations in workflows vs 3-4 baseline by preventing full artifact content pollution in orchestrator context windows.

---

### Finding 2: Hard Barrier Pattern for Artifact Validation

**Description**: Three-block pattern (Setup → Execute → Verify) enforces mandatory subagent delegation by inserting bash validation blocks between Task invocations.

**Location**:
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (lines 385-542)
- `/home/benjamin/.config/.claude/lib/workflow/validation-utils.sh` (lines 109-204)

**Evidence**:
```markdown
Block N: Phase Name
├── Block Na: Setup
│   ├── State transition (fail-fast)
│   ├── Variable persistence
│   └── Checkpoint reporting
├── Block Nb: Execute [CRITICAL BARRIER]
│   └── Task invocation (MANDATORY)
└── Block Nc: Verify
    ├── Artifact existence check
    ├── Fail-fast on missing outputs
    └── Error logging with recovery hints

# Validation function pattern
validate_agent_artifact() {
  local artifact_path="${1:-}"
  local min_size_bytes="${2:-10}"
  local artifact_type="${3:-artifact}"
  local max_attempts="${4:-10}"

  # Polling retry logic for agent artifact creation
  local attempt=0
  while [ $attempt -lt $max_attempts ]; do
    if [ -f "$artifact_path" ]; then
      break
    fi
    attempt=$((attempt + 1))
    sleep 1
  done

  # Fail-fast if file missing
  if [ ! -f "$artifact_path" ]; then
    log_command_error "agent_error" \
      "Agent failed to create $artifact_type after ${max_attempts}s" \
      "validate_agent_artifact"
    return 1
  fi

  # Validate minimum size
  actual_size=$(stat -c%s "$artifact_path" 2>/dev/null || echo 0)
  if [ "$actual_size" -lt "$min_size_bytes" ]; then
    log_command_error "agent_error" \
      "Agent produced undersized $artifact_type"
    return 1
  fi
}
```

**Impact**: 100% delegation success (bypass impossible), prevents context pollution from primary agents performing subagent work directly, enables modular architecture with focused agent responsibilities.

---

### Finding 3: Brief Summary Format for Coordinator Return Signals (96% Reduction)

**Description**: Coordinators return 80-token brief summaries in return signals instead of requiring primary agents to read 2,000-token full summary files for continuation decisions.

**Location**:
- `/home/benjamin/.config/.claude/docs/concepts/patterns/context-management.md` (lines 158-260)
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (lines 1112-1139)

**Evidence**:
```yaml
# Lean Coordinator Return Signal
ORCHESTRATION_COMPLETE:
  coordinator_type: "lean"
  summary_path: /path/to/summary.md
  summary_brief: "Completed Wave 1-2 (Phase 1,2) with 15 theorems. Context: 72%. Next: Continue Wave 3."
  phases_completed: [1, 2]
  theorem_count: 15
  work_remaining: Phase_3 Phase_4
  context_exhausted: false
  context_usage_percent: 72
  requires_continuation: true

# Primary Agent Parsing Logic (80 tokens vs 2,000 full file)
SUMMARY_BRIEF=$(grep "^summary_brief:" "$COORDINATOR_OUTPUT" | sed 's/^summary_brief:[[:space:]]*//')
PHASES_COMPLETED=$(grep "^phases_completed:" "$COORDINATOR_OUTPUT" | tr -d '[],"')

# Multi-Iteration Comparison
Without Brief Summary Pattern:
  Iteration 1: Read summary (2,000 tokens) - Total: 2,000 tokens
  Iteration 2: Read summary (2,000 tokens) - Total: 4,000 tokens
  Iteration 3: Read summary (2,000 tokens) - Total: 6,000 tokens
  Context exhausted at iteration 4 (8,000 tokens would exceed budget)

With Brief Summary Pattern:
  Iteration 1: Parse brief (80 tokens) - Total: 80 tokens
  Iteration 2: Parse brief (80 tokens) - Total: 160 tokens
  ...
  Iteration 20: Parse brief (80 tokens) - Total: 1,600 tokens (still under budget)
```

**Impact**: 96% context reduction per iteration, enables 20+ iterations vs 3-4 baseline, backward compatible with legacy summaries via fallback parsing.

---

### Finding 4: Artifact Creation Standards with YAML Metadata

**Description**: Agents create artifacts with YAML frontmatter containing metadata fields (report_type, topic, findings_count, recommendations_count) to enable metadata extraction without full file reads.

**Location**:
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (lines 55-78, 111-171)

**Evidence**:
```yaml
---
report_type: lean_research
topic: "Mathlib Theorems for Group Homomorphism"
findings_count: 12
recommendations_count: 5
---

# Research Report Template Structure
1. YAML frontmatter with metadata fields
2. Executive Summary (2-3 sentences)
3. Findings section (minimum 3 findings with evidence)
4. Recommendations section (minimum 3 actionable items)
5. References section (absolute paths with line numbers)

# Metadata Update Protocol (after research completion)
FINDINGS_COUNT=$(grep -c "^### Finding" "$REPORT_PATH")
RECOMMENDATIONS_COUNT=$(awk '/^## Recommendations$/,/^## [^R]/ {if (/^[0-9]+\./) count++} END {print count}' "$REPORT_PATH")
# Update YAML frontmatter using Edit tool
```

**Impact**: Enables coordinator metadata extraction (110 tokens) instead of full file reads (2,500 tokens) for 95% context reduction, provides structured artifact validation checkpoints.

---

### Finding 5: Progressive Context Reduction via Layered Architecture

**Description**: Context organized into layers with different retention policies: permanent (1,000 tokens), phase-scoped (pruned after phase), metadata (retained between phases), and transient (pruned immediately).

**Location**:
- `/home/benjamin/.config/.claude/docs/concepts/patterns/context-management.md` (lines 104-140, 286-344)

**Evidence**:
```markdown
Layer 1: Permanent (always retained)
- User request, workflow type, current phase, critical errors
Total: 500-1,000 tokens

Layer 2: Phase-Scoped (retained during phase, pruned after)
- Current phase instructions, agent invocations, verification checkpoints
Total: 2,000-4,000 tokens per phase

Layer 3: Metadata (retained between phases)
- Artifact paths, phase summaries, key findings
Total: 200-300 tokens per phase

Layer 4: Transient (pruned immediately after use)
- Full agent responses, detailed logs, intermediate calculations
Total: 0 tokens (pruned before next phase)

# 7-Phase Workflow Context Budget
- Layer 1: 1,000 tokens (4%)
- Layer 2: 3,000 tokens (12%) - current phase only
- Layer 3: 1,500 tokens (6%) - 5 completed phases × 300 tokens
- Layer 4: 0 tokens (pruned)
Total: 5,500 tokens (22% context usage across 6 phases)
```

**Impact**: <30% context usage across entire workflow lifecycles, enables 7-10 phase workflows vs 2-3 baseline, prevents context overflow through aggressive pruning.

---

### Finding 6: Invocation Plan Metadata for Planning Coordinators

**Description**: research-coordinator uses planning-only architecture, generating invocation metadata for primary agents to execute Task invocations rather than invoking research-specialist directly.

**Location**:
- `/home/benjamin/.config/.claude/agents/research-coordinator.md` (lines 28-39, 330-389, 473-602)

**Evidence**:
```markdown
# Planning-Only Coordinator Architecture
1. Decompose research request into topics
2. Pre-calculate report paths (hard barrier pattern)
3. Create invocation plan file with metadata
4. Return invocation metadata to primary agent
5. Primary agent executes Task invocations directly

# Invocation Plan File Structure
Expected Invocations: 3

Topics:
[0] Mathlib theorems for group homomorphism -> /path/001-mathlib-theorems.md
[1] Proof automation strategies -> /path/002-proof-automation.md
[2] Lean 4 project structure -> /path/003-project-structure.md

Status: PLAN_COMPLETE (ready for primary agent invocation)

# Return Signal Format
RESEARCH_COORDINATOR_COMPLETE: SUCCESS
topics_planned: 3
invocation_plan_path: /path/.invocation-plan.txt
context_usage_percent: 8

INVOCATION_PLAN_READY: 3
invocations: [
  {"topic": "Mathlib theorems", "report_path": "/path/001-mathlib-theorems.md"},
  {"topic": "Proof automation", "report_path": "/path/002-proof-automation.md"},
  {"topic": "Project structure", "report_path": "/path/003-project-structure.md"}
]
```

**Impact**: Enables primary agents to maintain parallel Task invocation control, reduces coordinator context usage to 8-10% (planning only), supports both automated decomposition and manual pre-decomposition modes.

---

## Recommendations

### 1. Standardize Metadata Fields in All Artifact YAML Frontmatter

**Priority**: HIGH

**Rationale**: Consistent metadata fields enable universal coordinator metadata extraction without custom parsing logic per artifact type.

**Implementation**:
- Define standard metadata fields: `artifact_type`, `topic`, `item_count`, `status`, `created_date`
- Update all agent behavioral files (research-specialist, plan-architect, implementer, test-executor) to use standard YAML frontmatter
- Create validation function `validate_artifact_metadata()` in validation-utils.sh
- Document metadata schema in `.claude/docs/reference/standards/artifact-metadata-standard.md`

**Benefits**: 95%+ context reduction applicable to all artifact types (research reports, implementation plans, test summaries), eliminates custom parsing logic duplication across coordinators.

---

### 2. Implement Context Budget Monitoring in All Commands

**Priority**: MEDIUM

**Rationale**: Proactive context usage monitoring enables early detection of context pollution before workflow failures.

**Implementation**:
- Add `get_context_usage_percentage()` function to unified-logger.sh or new context-metrics.sh library
- Instrument all multi-phase commands with context checkpoints after each phase
- Emit WARNING when usage exceeds 30% target
- Trigger aggressive pruning when usage exceeds 40%
- Document thresholds in `.claude/docs/reference/standards/context-budget-thresholds.md`

**Benefits**: Early warning system for context exhaustion, data-driven pruning decisions, measurable context reduction validation.

---

### 3. Create Coordinator Template with Hard Barrier Pattern

**Priority**: HIGH

**Rationale**: Standardized coordinator template ensures consistent delegation enforcement and artifact validation across all new coordinators.

**Implementation**:
- Extend `.claude/agents/templates/coordinator-template.md` with hard barrier pattern
- Include three-block structure (Setup → Execute → Verify) for all subagent delegations
- Provide copy-paste validation function examples using validation-utils.sh
- Add documentation references to hierarchical-agents-examples.md Example 6
- Create checklist for coordinator authors verifying hard barrier compliance

**Benefits**: 100% delegation success for all new coordinators, prevents context pollution anti-pattern propagation, reduces coordinator development time.

---

### 4. Document Brief Summary Format Standard

**Priority**: MEDIUM

**Rationale**: Formalize brief summary format to enable consistent parsing across all primary agents and coordinators.

**Implementation**:
- Create `.claude/docs/reference/standards/brief-summary-format.md`
- Define standard format: "Completed Wave X-Y (Phase A,B) with N items. Context: P%. Next: ACTION."
- Specify maximum character limits (150 chars for summary_brief)
- Document return signal fields: `summary_brief`, `coordinator_type`, `phases_completed`, `requires_continuation`
- Provide validation regex and parsing examples
- Add backward compatibility guidelines for legacy coordinators

**Benefits**: Consistent parsing logic across all primary agents, 96% context reduction standardized, future-proof coordinator integration.

---

### 5. Create Progressive Context Reduction Guide for Command Authors

**Priority**: MEDIUM

**Rationale**: Command authors need practical guidance on implementing layered context architecture and pruning policies.

**Implementation**:
- Create `.claude/docs/guides/development/progressive-context-reduction-guide.md`
- Provide layer classification decision matrix (permanent vs phase-scoped vs metadata vs transient)
- Document pruning trigger points (post-phase, post-agent, >30% usage, >40% emergency)
- Include workflow-specific pruning policy examples (research=aggressive, implementation=moderate, validation=conservative)
- Add code examples for checkpoint-based state externalization
- Reference context-management.md patterns with practical command integration examples

**Benefits**: Consistent <30% context usage across all multi-phase commands, reduced context overflow incidents, scalable workflow development.

---

## References

### Primary Documentation Sources

1. `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md`
   - Example 6: Hard Barrier Pattern (lines 385-542)
   - Example 7: Research Coordinator Pattern (lines 544-892)
   - Example 8: Lean Command Coordinator Optimization (lines 894-1185)

2. `/home/benjamin/.config/.claude/docs/concepts/patterns/context-management.md`
   - Metadata Extraction Pattern (lines 32-49)
   - Context Pruning (lines 51-84)
   - Layered Context Architecture (lines 104-140)
   - Brief Summary Return Pattern (lines 158-260)
   - Context Usage Targets and Monitoring (lines 346-515)

3. `/home/benjamin/.config/.claude/agents/research-coordinator.md`
   - Planning-only architecture (lines 28-39)
   - Invocation plan metadata generation (lines 330-389)
   - Return signal format (lines 543-602)

4. `/home/benjamin/.config/.claude/agents/research-specialist.md`
   - Artifact creation standards (lines 55-78)
   - YAML metadata fields (lines 111-171)
   - Metadata update protocol (lines 212-226)

5. `/home/benjamin/.config/.claude/lib/workflow/validation-utils.sh`
   - `validate_agent_artifact()` function (lines 109-204)
   - Hard barrier validation implementation

### Performance Metrics

- Context reduction: 95-96% via metadata-only passing and brief summaries
- Iteration capacity: 10-20+ iterations vs 3-4 baseline
- Context usage target: <30% across entire workflow lifecycle
- Validation success: 100% delegation enforcement with hard barrier pattern

### Integration Examples

1. `/lean-plan` - research-coordinator integration (3-topic parallel research)
2. `/lean-implement` - implementer-coordinator with brief summary parsing
3. `/create-plan` - automated topic detection and research delegation
4. `/research` - canonical hard barrier pattern implementation
